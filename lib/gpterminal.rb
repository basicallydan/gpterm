require 'optparse'

require_relative 'config'
require_relative 'client'

class GPTerminal
  def initialize
    @config = load_config
    @options = parse_options
    @client = Client.new(@config)
  end

  def run
    prompt = determine_prompt
    message = @client.first_prompt(prompt)

    puts 'Information gathering command:'
    puts message

    if message.downcase == '$$cannot_compute$$'
      puts 'Sorry, I cannot compute a command for this prompt. Try another'
      exit
    end

    if message.downcase == '$$no_gathering_needed$$'
      puts 'No information gathering needed'
      output = "No information gathering was needed."
    else
      puts 'Do you want to continue? The command will be executed (y/n)'
      continue = STDIN.gets.chomp

      unless continue.downcase == 'y'
        exit
      end

      puts 'Running command...'
      output = `#{message}`

      puts 'Output:'
      puts output
    end

    output = offer_more_information(output)

    while output.downcase != '$$no_more_information_needed$$'
      puts "You have been asked to provide more information with this command:"
      puts output
      puts "What is your response? (Type 'skip' to skip this step and force the final command to be generated)"

      response = STDIN.gets.chomp

      if response.downcase == 'skip'
        output = '$$no_more_information_needed$$'
      else
        output = offer_more_information(response)
      end
    end

    puts 'Requesting the next command...'

    message = @client.final_prompt(output)

    puts 'Generated command:'
    puts message

    puts 'Do you want to continue? The command will be executed (y/n)'

    continue = STDIN.gets.chomp

    unless continue.downcase == 'y'
      exit
    end

    output = `#{message}`

    puts 'Output:'
    puts output
  end

  private

  def load_config
    unless File.exist?(AppConfig::CONFIG_FILE)
      puts 'Welcome to GPTerminal! It looks like this is your first time using this application.'

      new_config = {}
      print "Before we get started, we need to configure the application. All the info you provide will be saved in #{AppConfig::CONFIG_FILE}."

      print "Enter your OpenAI API key's \"SECRET KEY\" value: "
      new_config['openapi_key'] = STDIN.gets.chomp

      print "Your PATH environment variable is: #{ENV['PATH']}"
      print 'Are you happy for your PATH to be sent to OpenAI to help with command generation? (y/n) '

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
    OptionParser.new do |opts|
      opts.banner = "Usage: gpterminal [preset] [options]"

      opts.on("-p", "--prompt PROMPT", "Set a custom prompt") do |v|
        options[:prompt] = v
      end

      opts.on("-s", "--save NAME,PROMPT", "Create a custom preset prompt") do |list|
        options[:preset_prompt] = list.split(',', 2)
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end

      opts.on("-k", "--key KEY", "Set the OpenAI API key") do |v|
        AppConfig.add_openapi_key(@config, v)
        puts "OpenAI API key saved"
        exit
      end

      opts.on("-P", "--send-path", "Send the PATH environment variable to OpenAI") do
        @config['send_path'] = true
        AppConfig.save_config(@config)
        puts "Your PATH environment variable will be sent to OpenAI to help with command generation"
        exit
      end
    end.parse!

    options
  end

  def determine_prompt
    if @options[:preset_prompt]
      name = @options[:preset_prompt][0]
      prompt = @options[:preset_prompt][1]
      AppConfig.add_preset(@config, name, prompt)
      puts "Preset prompt '#{name}' saved with prompt '#{prompt}'"
      exit
    end

    if ARGV.length == 1
      # collect a prompt from the preset prompts
      prompt = @config['presets'][ARGV[0]]

      unless prompt
        puts "Preset prompt not found: #{ARGV[0]}"
        exit
      end

      puts "Using preset prompt '#{prompt}'"
    elsif @options[:prompt]
      prompt = @options[:prompt]
    else
      puts 'Enter a prompt to generate text from:'
      prompt = STDIN.gets.chomp
    end

    prompt
  end

  def offer_more_information(output)
    output = @client.offer_information_prompt(output)
  end
end
