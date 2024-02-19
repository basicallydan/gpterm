require 'colorize'
require 'open3'

require_relative 'app_config'
require_relative 'client'
require_relative 'parse_options'
require_relative 'input'

# The colours work like this:
# - Output from STDOUT or STDERR is default
# - For the final command, if STDERR is there and the exit code is non-zero, it's red
# - Statements from this app are magenta
# - Questions from this app are yellow
# - Messages from the OpenAI API are blue

class GPTerm
  def initialize
    @config = AppConfig.load
    @options = ParseOptions.call(@config)
    @client = Client.new(@config)
  end

  def run
    if @options[:preset_prompt]
      name = @options[:preset_prompt][0]
      prompt = @options[:preset_prompt][1]
      AppConfig.add_preset(@config, name, prompt)
      exit_with_message("Preset prompt '#{name}' saved with prompt '#{prompt}'", :green)
    elsif @options[:prompt]
      start_conversation(@options[:prompt])
    end
  end

  private

  def execute_shell_command(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status.exitstatus]
  end

  def exit_with_message(message, color = nil)
    if color
      puts message.colorize(color)
    else
      puts message
    end

    exit
  end

  def start_conversation(prompt)
    info_prompt_response = @client.first_prompt(prompt)

    if info_prompt_response.downcase == '$$cannot_compute$$'
      exit_with_message('Sorry, a command could not be generated for that prompt. Try another.', :red)
    end

    if info_prompt_response.downcase == '$$no_gathering_needed$$'
      puts 'No information gathering needed'.colorize(:magenta)
      shell_output = nil
    else
      puts 'Information gathering command:'.colorize(:magenta)
      puts info_prompt_response.gsub(/^/, "#{"  $".colorize(:blue)} ")
      puts 'Do you want to execute this command? (Y/n then hit return)'.colorize(:yellow)
      continue = Input.yes_or_no

      unless continue.downcase == 'y'
        exit
      end

      puts 'Running command...'
      shell_output = `#{info_prompt_response}`

      if @config[:verbose]
        puts 'Shell output:'
        puts shell_output
      end
    end

    offer_prompt_response = @client.offer_information_prompt(shell_output, :shell_output_response)

    while offer_prompt_response.downcase != '$$no_more_information_needed$$'
      puts "You have been asked to provide more information with this command:".colorize(:magenta)
      puts offer_prompt_response.gsub(/^/, "#{"  >".colorize(:blue)} ")
      puts "What is your response? (Type 'skip' to skip this step and force the final command to be generated)".colorize(:yellow)

      user_question_response = Input.non_empty

      if user_question_response.downcase == 'skip'
        offer_prompt_response = '$$no_more_information_needed$$'
      else
        offer_prompt_response = @client.offer_information_prompt(user_question_response, :question_response)
      end
    end

    puts 'Requesting the next command...'.colorize(:magenta)

    goal_prompt_response = @client.final_prompt(offer_prompt_response)

    if goal_prompt_response.downcase == '$$cannot_compute$$'
      exit_with_message('Sorry, a command could not be generated for that prompt. Try another.', :red)
    end

    puts 'Generated command to accomplish your goal:'.colorize(:magenta)
    puts goal_prompt_response.gsub(/^/, "#{"  $".colorize(:green)} ")

    puts 'Do you want to execute this command? (Y/n then hit return)'.colorize(:yellow)

    continue = Input.yes_or_no

    unless continue.downcase == 'y'
      exit
    end

    commands = goal_prompt_response.split("\n")

    commands.each do |command|
      stdout, stderr, exit_status = execute_shell_command(command)
      if exit_status != 0
        puts "#{command} failed with the following output:".colorize(:red)
        puts "#{stderr.gsub(/^/, "  ")}".colorize(:red) if stderr.length > 0
        exit_with_message("  Exit status: #{exit_status}", :red)
      end
      puts stdout if stdout.length > 0
      # I'm doing this here because git for some reason always returns the output of a push to stderr,
      # even if it's successful. I don't want to show the output of a successful push as an error.
      puts stderr if stderr.length > 0
    end
  end
end
