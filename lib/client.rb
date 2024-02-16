require "openai"

class Client
  attr_reader :openapi_client
  attr_reader :config

  def initialize(config)
    @config = config
    @openapi_client = OpenAI::Client.new(access_token: config["openapi_key"])
  end

  def first_prompt(prompt)
    system_prompt = <<~PROMPT
      You are a command-line application being executed inside of a directory in a macOS environment, on the user's terminal command line.

      You are executed by running `gpterminal` in the terminal, and you are provided with a prompt to respond to with the -p flag.

      Users can add a preset prompt by running `gpterminal -s <name>,<prompt>`.

      The eventual output to the user would be a list of commands that they can run in their terminal to accomplish a task.

      You have the ability to run any command that this system can run, and you can read the output of those commands.

      The user is trying to accomplish a task using the terminal, but they are not sure how to do it.
    PROMPT

    if @config["send_path"]
      system_prompt += <<~PROMPT
        The user's PATH environment variable is:
        #{ENV["PATH"]}
      PROMPT
    end

    full_prompt = <<~PROMPT
      Your FIRST response should be a list of commands that will be automatically executed to gather more information about the user's system.
      - The commands MUST NOT make any changes to the user's system.
      - The commands MUST NOT make any changes to any files on the user's system.
      - The commands MUST NOT write to any files using the > or >> operators.
      - The commands MUST NOT use the touch command.
      - The commands MUST NOT use echo or any other command to write into files using the > or >> operators.
      - The commands MUST NOT send any data to any external servers.
      - The commands MUST NOT contain any placeholders in angle brackets like <this>.
      - The commands MUST NOT contain any plain language instructions, or backticks indicating where the commands begin or end.
      - The commands MAY gather information about the user's system, such as the version of a software package, or the contents of a file.
      - The commands CAN pipe their output into other commands.
      - The commands SHOULD tend to gather more verbose information INSTEAD OF more concise information.
      This will help you to provide a more accurate response to the user's goal.
      Therefore your FIRST response MUST contain ONLY a list of commands and nothing else.

      VALID example response. These commands are examples of commands which CAN be included in your FIRST response:

        for file in *; do cat "$file"; done
        which ls
        which git
        which brew
        git diff
        git status

      INVALID example response. These commands are examples of commands which MUST NOT be included in your FIRST response:

        touch file.txt
        git add .
        git push

      If you cannot create a VALID response, simply return the string "$$cannot_compute$$" and the user will be asked to provide a new prompt.
      If you do not need to gather more information, simply return the string "$$no_gathering_needed$$" and the next step will be executed.
      If you need to gather information directly from the user, you will be able to do so in the next step.

      The user's goal prompt is:
      "#{prompt}"
      Commands to execute to gather more information about the user's system before providing the response which will accomplish the user's goal:
    PROMPT

    @messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: full_prompt }
    ]

    response = openapi_client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: @messages,
        temperature: 0.6,
      }
    )
    content = response.dig("choices", 0, "message", "content")

    @messages << { role: "assistant", content: content }

    content
  end

  def offer_information_prompt(prompt)
    full_prompt = <<~PROMPT
      This is the output of the command you provided to the user in the previous step.

      #{prompt}

      Before you provide the user with the next command, you have the opportunity to ask the user to provide more information so you can better tailor your response to their needs.

      If you would like to ask the user for more information, please provide a prompt that asks the user for the information you need.
      - Your prompt MUST ONLY contain one question. You will be able to ask another question in the next step.
      If you have all the information you need, simply return the string "$$no_more_information_needed$$" and the next step will be executed.
    PROMPT

    @messages << { role: "user", content: full_prompt }

    response = openapi_client.chat(
      parameters: {
        model: "gpt-4-turbo-preview",
        messages: @messages,
        temperature: 0.6,
      }
    )

    content = response.dig("choices", 0, "message", "content")

    @messages << { role: "assistant", content: content }

    content
  end

  def final_prompt(prompt)
    full_prompt = <<~PROMPT
      This is the output of the command you provided to the user in the previous step.

      #{prompt}

      Your NEXT response should be a list of commands that will be automatically executed to fulfill the user's goal.
      - The commands may make changes to the user's system.
      - The commands may install new software using package managers like Homebrew
      - The commands MUST all start with a valid command that you would run in the terminal
      - The commands MUST NOT contain any placeholders in angle brackets like <this>.
      - The response MUST NOT contain any plain language instructions, or backticks indicating where the commands begin or end.
      - THe response MUST NOT start or end with backticks.
      - The response MUST NOT end with a newline character.
      Therefore your NEXT response MUST contain ONLY a list of commands and nothing else.

      VALID example response. These commands are examples of commands which CAN be included in your FINAL response:

        ls
        mkdir new_directory
        brew install git
        git commit -m "This is a great commit message"

      If you cannot keep to this restriction, simply return the string "$$cannot_compute$$" and the user will be asked to provide a new prompt.
    PROMPT

    @messages << { role: "user", content: full_prompt }

    response = openapi_client.chat(
      parameters: {
        model: "gpt-4-turbo-preview",
        messages: @messages,
        temperature: 0.7,
      }
    )
    content = response.dig("choices", 0, "message", "content")

    @messages << { role: "assistant", content: content }

    content
  end
end