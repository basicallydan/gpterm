require "openai"

class Client
  attr_reader :openapi_client

  def initialize(config)
    @openapi_client = OpenAI::Client.new(access_token: config["openapi_key"])
  end

  def first_prompt(prompt, max_tokens: 50, temperature: 0.7, stop: nil)
    # Get the user's PATH and put it in a string
    path = ENV["PATH"]

    system_prompt = <<~PROMPT
      You are a command-line application being executed inside of a directory in a macOS environment, on the user's terminal command line.

      You have the ability to run any command that this system can run, and you can read the output of those commands.

      The user is trying to accomplish a task using the terminal, but they are not sure how to do it.

      The user's PATH is:
      #{path}
    PROMPT

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

        which ls
        which git
        which brew
        git diff
        git status
        for file in *; do cat "$file"; done

      INVALID example response. These commands are examples of commands which MUST NOT be included in your FIRST response:

        touch file.txt
        git add .
        git push

      If you cannot create a VALID response, simply return the string "$$cannot_compute$$" and the user will be asked to provide a new prompt.

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

  def second_prompt(prompt, max_tokens: 50, temperature: 0.7, stop: nil)
    full_prompt = <<~PROMPT
      This is the output of the command you provided to the user in the previous step.

      #{prompt}

      Your NEXT response should be a list of commands that will be automatically executed to fulfill the user's goal.
      - The commands may make changes to the user's system.
      - The commands may install new software using package managers like Homebrew
      - The commands MUST all start with a valid command that you would run in the terminal
      - The commands MUST NOT contain any placeholders in angle brackets like <this>.
      - The response MUST NOT contain any plain language instructions, or backticks indicating where the commands begin or end.
      Therefore your NEXT response MUST contain ONLY a list of commands and nothing else.

      Valid example response:

        ls
        mkdir new_directory
        brew install git

      If you cannot keep to this restriction, simply return the string "$$cannot_compute$$" and the user will be asked to provide a new prompt.
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
end