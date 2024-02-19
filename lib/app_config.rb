require 'colorize'
require 'yaml'

require_relative 'input'

module AppConfig
  CONFIG_FILE = File.join(Dir.home, '.gpterm', 'config.yml').freeze

  def self.load
    # Check if the directory exists, if not, create it
    unless File.directory?(File.dirname(CONFIG_FILE))
      Dir.mkdir(File.dirname(CONFIG_FILE))
    end

    unless File.exist?(self::CONFIG_FILE)
      puts 'Welcome to gpterm! It looks like this is your first time using this application.'.colorize(:magenta)

      new_config = {}
      puts "Before we get started, we need to configure the application. All the info you provide will be saved in #{self::CONFIG_FILE}.".colorize(:magenta)

      puts "Enter your OpenAI API key's \"SECRET KEY\" value then hit return: ".colorize(:yellow)
      new_config['openapi_key'] = Input.non_empty

      puts "Your PATH environment variable is: #{ENV['PATH']}".colorize(:magenta)
      puts 'Are you happy for your PATH to be sent to OpenAI to help with command generation? (Y/n then hit return) '.colorize(:yellow)

      input = Input.yes_or_no

      if input == 'y'
        new_config['send_path'] = true
      else
        new_config['send_path'] = false
      end

      default_model = 'gpt-4-turbo-preview'

      puts "The default model is #{default_model}. If you would like to change it please enter the name of your preferred model:".colorize(:yellow)
      new_config['model'] = STDIN.gets.chomp.strip || default_model

      self.save_config(new_config)

      puts "Configuration saved to #{self::CONFIG_FILE}".colorize(:green)

      new_config
    else
      self.load_config_from_file
    end
  end

  def self.load_config_from_file
    YAML.load_file(CONFIG_FILE)
  end

  def self.save_config(config)
    File.write(CONFIG_FILE, config.to_yaml)
  end

  def self.add_openapi_key(config, openapi_key)
    config['openapi_key'] = openapi_key
    save_config(config)
  end

  def self.add_preset(config, preset_name, preset_prompt)
    # This is a YAML file so we need to make sure the presets key exists
    config['presets'] ||= {}
    config['presets'][preset_name] = preset_prompt
    save_config(config)
  end
end
