require_relative "ssl_poler/version"
require_relative "ssl_poler/certificate_checker"
require_relative "ssl_poler/config_loader"
require_relative "ssl_poler/cli"

module SslPoler
  class Error < StandardError; end
end