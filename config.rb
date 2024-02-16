require 'yaml'

module AppConfig
  CONFIG_FILE = File.join(Dir.home, '.gpterminal', 'config.yml').freeze

  # Check if the directory exists, if not, create it
  unless File.directory?(File.dirname(CONFIG_FILE))
    Dir.mkdir(File.dirname(CONFIG_FILE))
  end

  def self.load_config
    YAML.load_file(CONFIG_FILE)
  rescue Errno::ENOENT
    default_config
  end

  def self.save_config(config)
    File.write(CONFIG_FILE, config.to_yaml)
  end

  def self.default_config
    {
      'openapi_key' => ''
    }
  end
end
