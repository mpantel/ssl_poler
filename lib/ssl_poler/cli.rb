require "optparse"

module SslPoler
  class CLI
    def initialize(args)
      @args = args
      @config_path = nil
      @options = {
        format: :text,
        warning_days: 30
      }
    end

    def run
      parse_options

      if @config_path.nil?
        puts "Error: Config file is required"
        puts @option_parser
        exit 1
      end

      config_loader = ConfigLoader.new(@config_path)
      config_loader.load

      results = check_certificates(config_loader.urls)
      display_results(results)

      exit_code = results.any? { |r| r[:error] || r[:expired] || r[:expires_soon] } ? 1 : 0
      exit exit_code
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    private

    def parse_options
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: ssl_poler [options]"

        opts.on("-c", "--config PATH", "Path to YAML config file (required)") do |path|
          @config_path = path
        end

        opts.on("-f", "--format FORMAT", [:text, :json], "Output format (text, json)") do |format|
          @options[:format] = format
        end

        opts.on("-w", "--warning-days DAYS", Integer, "Days before expiration to warn (default: 30)") do |days|
          @options[:warning_days] = days
        end

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit 0
        end

        opts.on("-v", "--version", "Show version") do
          puts "ssl_poler version #{VERSION}"
          exit 0
        end
      end

      @option_parser.parse!(@args)
    end

    def check_certificates(urls)
      results = []

      urls.each do |entry|
        puts "Checking #{entry[:name]}..." if @options[:format] == :text

        checker = CertificateChecker.new(entry[:url])
        success = checker.check

        if success
          info = checker.certificate_info
          info[:name] = entry[:name]
          info[:url] = entry[:url]
          info[:expires_soon] = info[:expires_in_days] && info[:expires_in_days] <= @options[:warning_days]
          results << info
        else
          results << {
            name: entry[:name],
            url: entry[:url],
            error: checker.error
          }
        end
      end

      results
    end

    def display_results(results)
      case @options[:format]
      when :json
        require "json"
        puts JSON.pretty_generate(results)
      else
        display_text_results(results)
      end
    end

    def display_text_results(results)
      puts "\n" + "=" * 80
      puts "SSL Certificate Check Results"
      puts "=" * 80

      results.each do |result|
        puts "\n#{result[:name]} (#{result[:url]})"
        puts "-" * 80

        if result[:error]
          puts "  Status: ERROR"
          puts "  Error:  #{result[:error]}"
          next
        end

        puts "  Status:     #{status_text(result)}"
        puts "  Subject:    #{result[:subject]}"
        puts "  Issuer:     #{result[:issuer]}"
        puts "  Valid From: #{result[:not_before]}"
        puts "  Valid To:   #{result[:not_after]}"
        puts "  Expires In: #{result[:expires_in_days]} days"
        puts "  Serial:     #{result[:serial_number]}"
        puts "  Algorithm:  #{result[:signature_algorithm]}"
        puts "  Key:        #{result[:public_key_algorithm]} (#{result[:key_size]} bits)"
      end

      puts "\n" + "=" * 80
      display_summary(results)
    end

    def status_text(result)
      if result[:expired]
        "EXPIRED"
      elsif result[:expires_soon]
        "WARNING (expires in #{result[:expires_in_days]} days)"
      else
        "OK"
      end
    end

    def display_summary(results)
      total = results.size
      errors = results.count { |r| r[:error] }
      expired = results.count { |r| r[:expired] }
      expiring_soon = results.count { |r| r[:expires_soon] && !r[:expired] }
      ok = total - errors - expired - expiring_soon

      puts "Summary:"
      puts "  Total:         #{total}"
      puts "  OK:            #{ok}"
      puts "  Expiring Soon: #{expiring_soon}"
      puts "  Expired:       #{expired}"
      puts "  Errors:        #{errors}"
      puts ""
      display_summary_table(results)
      puts "=" * 80
    end

    def display_summary_table(results)
      # Calculate column widths
      max_name_width = [results.map { |r| r[:name].to_s.length }.max || 4, 20].min
      max_url_width = [results.map { |r| r[:url].to_s.length }.max || 3, 40].min
      status_width = 10
      expiry_width = 19

      # Print header
      puts "  " + "-" * (max_name_width + max_url_width + status_width + expiry_width + 10)
      printf("  %-#{max_name_width}s | %-#{max_url_width}s | %-#{status_width}s | %-#{expiry_width}s\n",
             "Name", "URL", "Status", "Expiry Date")
      puts "  " + "-" * (max_name_width + max_url_width + status_width + expiry_width + 10)

      # Print rows
      results.each do |result|
        name = result[:name].to_s.length > max_name_width ?
               result[:name].to_s[0...(max_name_width-3)] + "..." :
               result[:name].to_s

        url = result[:url].to_s.length > max_url_width ?
              result[:url].to_s[0...(max_url_width-3)] + "..." :
              result[:url].to_s

        if result[:error]
          status = "ERROR"
          expiry = "N/A"
        elsif result[:expired]
          status = "EXPIRED"
          expiry = result[:not_after].strftime("%Y-%m-%d")
        elsif result[:expires_soon]
          status = "WARNING"
          expiry = result[:not_after].strftime("%Y-%m-%d")
        else
          status = "OK"
          expiry = result[:not_after].strftime("%Y-%m-%d")
        end

        printf("  %-#{max_name_width}s | %-#{max_url_width}s | %-#{status_width}s | %-#{expiry_width}s\n",
               name, url, status, expiry)
      end

      puts "  " + "-" * (max_name_width + max_url_width + status_width + expiry_width + 10)
    end
  end
end