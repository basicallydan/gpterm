#!/usr/bin/env ruby
require_relative 'config'
require_relative 'lib/client'
require 'optparse'

config = unless File.exist?(AppConfig::CONFIG_FILE)
  puts 'Welcome to GPTerminal! It looks like this is your first time using this application.'

  new_config = {}
  print 'Enter OpenAI API key: '
  new_config['openapi_key'] = STDIN.gets.chomp

  AppConfig.save_config(new_config)

  new_config
else
  AppConfig.load_config
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: optparse_example.rb [options]"

  opts.on("-p", "--prompt PROMPT", "Set a custom prompt") do |v|
    options[:prompt] = v
  end

  opts.on("-s", "--save NAME,PROMPT", "Create a custom preset prompt") do |list|
    # Split the list into two items, keepng in mind that there could be multiple commas but the first
    # is the only one that matters
    options[:preset_prompt] = list.split(',', 2)
  end
end.parse!

if options[:preset_prompt]
  name = options[:preset_prompt][0]
  prompt = options[:preset_prompt][1]
  AppConfig.add_preset(config, name, prompt)
  puts "Preset prompt '#{name}' saved with prompt '#{prompt}'"
  exit
end

if ARGV.length == 1
  # collect a prompt from the preset prompts
  prompt = config['presets'][ARGV[0]]

  unless prompt
    puts "Preset prompt not found: #{ARGV[0]}"
    exit
  end

  puts "Using preset prompt '#{prompt}'"
elsif options[:prompt]
  prompt = options[:prompt]
else
  puts 'Enter a prompt to generate text from:'
  prompt = STDIN.gets.chomp
end

puts 'Generating text...'

client = Client.new(config)
message = client.first_prompt(prompt)

# Check if the user wants to continue
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

puts 'Requesting the next command...'

message = client.second_prompt(output)

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
