require "yaml"

module SslPoler
  class ConfigLoader
    attr_reader :config, :urls

    def initialize(config_path)
      @config_path = config_path
      @config = nil
      @urls = []
    end

    def load
      raise Error, "Config file not found: #{@config_path}" unless File.exist?(@config_path)

      @config = YAML.load_file(@config_path)
      validate_config!
      extract_urls
      self
    rescue Psych::SyntaxError => e
      raise Error, "Invalid YAML syntax in config file: #{e.message}"
    end

    private

    def validate_config!
      raise Error, "Config file is empty" if @config.nil? || @config.empty?
      raise Error, "Config must contain 'urls' key" unless @config.key?("urls")
      raise Error, "URLs must be an array" unless @config["urls"].is_a?(Array)
      raise Error, "URLs array cannot be empty" if @config["urls"].empty?
    end

    def extract_urls
      @urls = @config["urls"].map do |entry|
        case entry
        when String
          { url: entry, name: entry }
        when Hash
          {
            url: entry["url"] || entry[:url],
            name: entry["name"] || entry[:name] || entry["url"] || entry[:url]
          }
        else
          raise Error, "Invalid URL entry: #{entry.inspect}"
        end
      end

      @urls.each do |entry|
        raise Error, "URL cannot be nil or empty" if entry[:url].nil? || entry[:url].empty?
      end
    end
  end
end