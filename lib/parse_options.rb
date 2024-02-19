require 'optparse'

class ParseOptions
  def self.call(config)
    options = {}
    subcommands = {
      'preset' => {
        option_parser: OptionParser.new do |opts|
          opts.banner = "gpterm preset <name> <prompt>"
        end,
        argument_parser: ->(args) {
          if args.length < 2
            options[:prompt] = config['presets'][args[0]]
          else
            options[:preset_prompt] = [args[0], args[1]]
          end
        }
      },
      'config' => {
        option_parser: OptionParser.new do |opts|
          opts.banner = "gpterm config [--openapi_key <value>|--send_path <true|false>]"
          opts.on("--openapi_key VALUE", "Set the OpenAI API key") do |v|
            AppConfig.add_openapi_key(config, v)
            exit_with_message("OpenAI API key saved")
          end
          opts.on("--send_path", "Send the PATH environment variable to OpenAI") do
            config['send_path'] = true
            AppConfig.save_config(config)
            exit_with_message("Your PATH environment variable will be sent to OpenAI to help with command generation")
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
      exit_with_message(main)
    elsif command
      options[:prompt] = command
    else
      puts 'Enter a prompt to generate text from:'.colorize(:yellow)
      options[:prompt] = Input.non_empty
    end

    options
  end
end