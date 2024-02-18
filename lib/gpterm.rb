require 'optparse'
require 'colorize'
require 'open3'

require_relative 'config'
require_relative 'client'

# The colours work like this:
# - Output from STDOUT or STDERR is default
# - For the final command, if STDERR is there and the exit code is non-zero, it's red
# - Statements from this app are magenta
# - Questions from this app are yellow
# - Messages from the OpenAI API are blue

class GPTerm
  def initialize
    @config = load_config
    @options = parse_options
    @client = Client.new(@config)
  end

  def run
    if @options[:preset_prompt]
      name = @options[:preset_prompt][0]
      prompt = @options[:preset_prompt][1]
      AppConfig.add_preset(@config, name, prompt)
      puts "Preset prompt '#{name}' saved with prompt '#{prompt}'".colorize(:green)
      exit
    elsif @options[:prompt]
      start_prompt(@options[:prompt])
    end
  end

  private

  def execute_command(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status.exitstatus]
  end

  def start_prompt(prompt)
    message = @client.first_prompt(prompt)

    if message.downcase == '$$cannot_compute$$'
      puts 'Sorry, a command could not be generated for that prompt. Try another.'.colorize(:red)
      exit
    end

    if message.downcase == '$$no_gathering_needed$$'
      puts 'No information gathering needed'.colorize(:magenta)
      output = "No information gathering was needed."
    elsif message.downcase == '$$cannot_compute$$'
      puts 'Sorry, a command could not be generated for that prompt. Try another.'.colorize(:red)
      exit
    else
      puts 'Information gathering command:'.colorize(:magenta)
      puts message.gsub(/^/, "#{"  $".colorize(:blue)} ")
      puts 'Do you want to execute this command? (Y/n)'.colorize(:yellow)
      continue = STDIN.gets.chomp

      unless continue.downcase == 'y'
        exit
      end

      puts 'Running command...'
      output = `#{message}`

      if @config[:verbose]
        puts 'Output:'
        puts output
      end
    end

    output = @client.offer_information_prompt(output, :shell_output_response)

    while output.downcase != '$$no_more_information_needed$$'
      puts "You have been asked to provide more information with this command:".colorize(:magenta)
      puts output.gsub(/^/, "#{"  >".colorize(:blue)} ")
      puts "What is your response? (Type 'skip' to skip this step and force the final command to be generated)".colorize(:yellow)

      response = STDIN.gets.chomp

      if response.downcase == 'skip'
        output = '$$no_more_information_needed$$'
      else
        output = @client.offer_information_prompt(response, :question_response)
      end
    end

    puts 'Requesting the next command...'.colorize(:magenta)

    message = @client.final_prompt(output)

    if message.downcase == '$$cannot_compute$$'
      puts 'Sorry, a command could not be generated for that prompt. Try another.'.colorize(:red)
      exit
    end

    puts 'Generated command to accomplish your goal:'.colorize(:magenta)
    puts message.gsub(/^/, "#{"  $".colorize(:green)} ")

    puts 'Do you want to execute this command? (Y/n)'.colorize(:yellow)

    continue = STDIN.gets.chomp

    unless continue.downcase == 'y'
      exit
    end

    commands = message.split("\n")

    commands.each do |command|
      stdout, stderr, exit_status = execute_command(command)
      if exit_status != 0
        puts "#{command} failed with the following output:".colorize(:red)
        puts "#{stderr.gsub(/^/, "  ")}".colorize(:red) if stderr.length > 0
        puts "  Exit status: #{exit_status}".colorize(:red)
        exit
      end
      puts stdout if stdout.length > 0
      # I'm doing this here because git for some reason always returns the output of a push to stderr,
      # even if it's successful. I don't want to show the output of a successful push as an error.
      puts stderr if stderr.length > 0
    end
  end

  def load_config
    unless File.exist?(AppConfig::CONFIG_FILE)
      puts 'Welcome to gpterm! It looks like this is your first time using this application.'.colorize(:magenta)

      new_config = {}
      puts "Before we get started, we need to configure the application. All the info you provide will be saved in #{AppConfig::CONFIG_FILE}.".colorize(:magenta)

      puts "Enter your OpenAI API key's \"SECRET KEY\" value: ".colorize(:yellow)
      new_config['openapi_key'] = STDIN.gets.chomp

      puts "Your PATH environment variable is: #{ENV['PATH']}".colorize(:magenta)
      puts 'Are you happy for your PATH to be sent to OpenAI to help with command generation? (Y/n) '.colorize(:yellow)

      if STDIN.gets.chomp.downcase == 'y'
        new_config['send_path'] = true
      else
        new_config['send_path'] = false
      end

      AppConfig.save_config(new_config)

      new_config
    else
      AppConfig.load_config
    end
  end

  def parse_options
    options = {}
    subcommands = {
      'preset' => {
        option_parser: OptionParser.new do |opts|
          opts.banner = "gpterm preset <name> <prompt>"
        end,
        argument_parser: ->(args) {
          if args.length < 2
            options[:prompt] = @config['presets'][args[0]]
          else
            options[:preset_prompt] = [args[0], args[1]]
          end
        }
      },
      'config' => {
        option_parser: OptionParser.new do |opts|
          opts.banner = "gpterm config [--openapi_key <value>|--send_path <true|false>]"
          opts.on("--openapi_key VALUE", "Set the OpenAI API key") do |v|
            AppConfig.add_openapi_key(@config, v)
            puts "OpenAI API key saved"
            exit
          end
          opts.on("--send_path", "Send the PATH environment variable to OpenAI") do
            @config['send_path'] = true
            AppConfig.save_config(@config)
            puts "Your PATH environment variable will be sent to OpenAI to help with command generation"
            exit
          end
        end
      }
    }

    main = OptionParser.new do |opts|
      opts.banner = "Usage:"
      opts.banner += "\n\ngpterm <prompt> [options] [subcommand [options]]"
      opts.banner += "\n\nSubcommands:"
      subcommands.each do |name, subcommand|
        opts.banner += "\n  #{name} - #{subcommand[:option_parser].banner}"
      end
      opts.banner += "\n\nOptions:"
      opts.on("-v", "--verbose", "Run verbosely") do |v|
        options[:verbose] = true
      end
    end

    command = ARGV.shift

    main.order!
    if subcommands.key?(command)
      subcommands[command][:option_parser].parse!
      subcommands[command][:argument_parser].call(ARGV) if subcommands[command][:argument_parser]
    elsif command == 'help'
      puts main
      exit
    elsif command
      options[:prompt] = command
    else
      puts 'Enter a prompt to generate text from:'.colorize(:yellow)
      options[:prompt] = STDIN.gets.chomp
    end

    options
  end
end
