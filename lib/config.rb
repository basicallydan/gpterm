require 'yaml'

module AppConfig
  CONFIG_FILE = File.join(Dir.home, '.gpterm', 'config.yml').freeze

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

  def self.default_config
    {
      'openapi_key' => ''
    }
  end
end
