# SslPoler

A Ruby gem for checking SSL certificate status from multiple URLs defined in a YAML configuration file. Monitor certificate expiration dates, issuers, and other important certificate details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ssl_poler'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install ssl_poler
```

## Usage

### 1. Create a YAML configuration file

Create a file (e.g., `config.yml`) with your URLs:

```yaml
urls:
  - https://example.com
  - https://google.com
  - name: GitHub
    url: https://github.com
  - name: Ruby Gems
    url: https://rubygems.org
```

URLs can be specified as simple strings or as objects with `name` and `url` keys.

### 2. Run the CLI

```bash
$ ssl_poler --config config.yml
```

### CLI Options

```
Usage: ssl_poler [options]
    -c, --config PATH                Path to YAML config file (required)
    -f, --format FORMAT              Output format (text, json)
    -w, --warning-days DAYS          Days before expiration to warn (default: 30)
    -h, --help                       Show this help message
    -v, --version                    Show version
```

### Examples

**Basic check:**
```bash
$ ssl_poler --config config.yml
```

**JSON output:**
```bash
$ ssl_poler --config config.yml --format json
```

**Custom warning threshold (warn if expiring within 60 days):**
```bash
$ ssl_poler --config config.yml --warning-days 60
```

### Sample Output

```
================================================================================
SSL Certificate Check Results
================================================================================

example.com (https://example.com)
--------------------------------------------------------------------------------
  Status:     OK
  Subject:    CN=example.com
  Issuer:     CN=DigiCert TLS RSA SHA256 2020 CA1, O=DigiCert Inc, C=US
  Valid From: 2024-01-15 00:00:00 UTC
  Valid To:   2025-02-15 23:59:59 UTC
  Expires In: 125 days
  Serial:     12345678901234567890
  Algorithm:  sha256WithRSAEncryption
  Key:        OpenSSL::PKey::RSA (2048 bits)

================================================================================
Summary:
  Total:         4
  OK:            3
  Expiring Soon: 1
  Expired:       0
  Errors:        0

  -----------------------------------------------------------------------
  Name                 | URL                  | Status     | Expiry Date
  -----------------------------------------------------------------------
  example.com          | https://example.com  | OK         | 2025-02-15
  google.com           | https://google.com   | WARNING    | 2025-01-20
  GitHub               | https://github.com   | OK         | 2025-06-10
  Ruby Gems            | https://rubygems.org | OK         | 2025-08-30
  -----------------------------------------------------------------------
================================================================================
```

## Programmatic Usage

You can also use the gem programmatically in your Ruby code:

```ruby
require 'ssl_poler'

# Check a single URL
checker = SslPoler::CertificateChecker.new('https://example.com')
if checker.check
  info = checker.certificate_info
  puts "Expires in #{info[:expires_in_days]} days"
  puts "Valid: #{info[:valid]}"
  puts "Expired: #{info[:expired]}"
else
  puts "Error: #{checker.error}"
end

# Load and check multiple URLs from config
config = SslPoler::ConfigLoader.new('config.yml')
config.load

config.urls.each do |entry|
  checker = SslPoler::CertificateChecker.new(entry[:url])
  checker.check
  info = checker.certificate_info
  puts "#{entry[:name]}: #{info[:expires_in_days]} days remaining"
end
```

## Certificate Information

The gem provides the following information for each certificate:

- **Subject**: The entity to which the certificate is issued
- **Issuer**: The entity that issued the certificate
- **Serial Number**: Unique identifier for the certificate
- **Valid From**: Certificate start date
- **Valid To**: Certificate expiration date
- **Expires In**: Number of days until expiration
- **Expired**: Boolean indicating if certificate has expired
- **Expires Soon**: Boolean indicating if certificate expires within warning threshold
- **Valid**: Boolean indicating if certificate is currently valid
- **Version**: X.509 version
- **Signature Algorithm**: Algorithm used to sign the certificate
- **Public Key Algorithm**: Type of public key (RSA, EC, etc.)
- **Key Size**: Size of the public key in bits

## Exit Codes

The CLI uses the following exit codes:

- `0`: All certificates are valid and not expiring soon
- `1`: One or more certificates have errors, are expired, or expiring soon

This makes it easy to integrate with monitoring systems and CI/CD pipelines.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/ssl_poler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).