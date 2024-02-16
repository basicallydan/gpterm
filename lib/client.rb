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
      You are an expert in writing commands for the macOS terminal.

      The user is trying to accomplish a task using the terminal, but they are not sure how to do it.

      The user's PATH is:
      #{path}
      The user will provide a goal, and your role is to provide the command that the user should run in the terminal to accomplish that goal.

    PROMPT

    full_prompt = <<~PROMPT
      Your FIRST response should be a list of commands that will be automatically executed to gather more information about the user's system.
      - The commands MUST NOT make any changes to the user's system.
      - The commands MUST NOT contain any placeholders in angle brackets like <this>.
      - The commands MUST NOT contain any plain language instructions, or backticks indicating where the commands begin or end.
      - The commands MUST all start with `which` to find out if a command is installed.
      This will help you to provide a more accurate response to the user's goal.
      Therefore your FIRST response MUST contain ONLY a list of commands and nothing else. Example response:

      which ls
      which git
      which brew

      If you cannot keep to this restriction, simply return the string "$$cannot_compute$$" and the user will be asked to provide a new prompt.

      The user's goal is:
      #{prompt}
    PROMPT

    @messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: full_prompt }
    ]

    response = openapi_client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: @messages,
        temperature: 0.7,
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
      Therefore your NEXT response MUST contain ONLY a list of commands and nothing else. Example response:

      ls
      mkdir new_directory
      brew install git

      If you cannot keep to this restriction, simply return the string "$$cannot_compute$$" and the user will be asked to provide a new prompt.
    PROMPT

    @messages << { role: "user", content: full_prompt }

    response = openapi_client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: @messages,
        temperature: 0.7,
      }
    )
    content = response.dig("choices", 0, "message", "content")

    @messages << { role: "assistant", content: content }

    content
  end
end