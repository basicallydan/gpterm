#!/usr/bin/env ruby
require_relative 'config'
require_relative 'lib/client'

config = unless File.exist?(AppConfig::CONFIG_FILE)
  puts 'Welcome to GPTerminal! It looks like this is your first time using this application.'

  new_config = {}
  print 'Enter OpenAI API key: '
  new_config['openapi_key'] = gets.chomp

  AppConfig.save_config(new_config)

  new_config
else
  AppConfig.load_config
end

client = Client.new(config)

puts 'Enter a prompt to generate text from:'
prompt = gets.chomp

puts 'Generating text...'

message = client.first_prompt(prompt)

# Check if the user wants to continue
puts 'Information gathering command:'
puts message

if message.downcase == '$$cannot_compute$$'
  puts 'Sorry, I cannot compute a command for this prompt. Try another'
  exit
end

puts 'Do you want to continue? The command will be executed (y/n)'

continue = gets.chomp

unless continue.downcase == 'y'
  exit
end

puts 'Running command...'
output = `#{message}`

puts 'Output:'
puts output

puts 'Requesting the next command...'

message = client.second_prompt(output)

puts 'Generated command:'
puts message

puts 'Do you want to continue? The command will be executed (y/n)'

continue = gets.chomp

unless continue.downcase == 'y'
  exit
end
output = `#{message}`

puts 'Output:'
puts output
