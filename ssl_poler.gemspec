require_relative "lib/ssl_poler/version"

Gem::Specification.new do |spec|
  spec.name          = "ssl_poler"
  spec.version       = SslPoler::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "Check SSL certificate status for multiple URLs"
  spec.description   = "A Ruby gem that reads URLs from a YAML configuration and checks their SSL certificate status, including expiration dates, issuers, and more."
  spec.homepage      = "https://github.com/yourusername/ssl_poler"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir        = "exe"
  spec.executables   = ["ssl_poler"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end