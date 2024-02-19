require "openai"
require 'yaml'

class CommandGenerator
  attr_reader :openai_client
  attr_reader :config

  def initialize(config)
    @config = config
    @openai_client = OpenAI::Client.new(access_token: config["openapi_key"])
    @prompts = YAML.load_file(File.join(__dir__, '..', 'config', 'prompts.yml'))
  end

  def first_prompt(user_goal_prompt)
    system_prompt = @prompts["system"]

    if @config["send_path"]
      system_prompt += <<~PROMPT
        # ADDITIONAL CONTEXT:

        The user's PATH environment variable is:
        #{ENV["PATH"]}
      PROMPT
    end

    user_prompt = @prompts["info_gathering"]
    user_prompt += <<~PROMPT
      The user's GOAL PROMPT is:

      "#{user_goal_prompt}"

      Please respond with one or more commands to execute to gather more information about the user's system before providing the response which will accomplish the user's goal.

      COMMANDS:
    PROMPT

    @messages = [
      { role: "system", content: system_prompt }
    ]

    continue_conversation(user_prompt)
  end

  def offer_information_prompt(previous_output, previous_output_type = :question_response)
    question_prompt = if previous_output_type == :question_response
      <<~PROMPT
        This is the output of the question you asked the user in the previous step.

        #{previous_output}
      PROMPT
    else
      <<~PROMPT
        This is the output of the command you provided to the user in the previous step.

        #{previous_output}
      PROMPT
    end

    question_prompt += @prompts["user_question"]

    continue_conversation(question_prompt)
  end

  def final_prompt(prompt)
    goal_commands_prompt = <<~PROMPT
      This is the output of the command you provided to the user in the previous step.

      #{prompt}

    PROMPT

    goal_commands_prompt += @prompts["goal_commands"]

    continue_conversation(goal_commands_prompt)
  end

  private

  def continue_conversation(prompt)
    @messages << { role: "user", content: prompt }

    model = @config["model"]

    if !model || model.strip.length == 0
      model = "gpt-4-turbo-preview"
    end

    response = openai_client.chat(
      parameters: {
        model: model,
        messages: @messages,
        temperature: 0.6,
      }
    )
    content = response.dig("choices", 0, "message", "content")

    @messages << { role: "assistant", content: content }

    content
  end
end