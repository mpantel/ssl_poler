require "openssl"
require "net/http"
require "uri"

module SslPoler
  class CertificateChecker
    attr_reader :url, :certificate, :error

    def initialize(url)
      @url = url
      @certificate = nil
      @error = nil
    end

    def check
      uri = parse_url(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # We just want to inspect the cert, not validate the connection

      http.start do |connection|
        @certificate = connection.peer_cert
      end

      true
    rescue => e
      @error = e.message
      false
    end

    def certificate_info
      return nil unless certificate

      {
        subject: certificate.subject.to_s,
        issuer: certificate.issuer.to_s,
        serial_number: certificate.serial.to_s,
        not_before: certificate.not_before,
        not_after: certificate.not_after,
        expires_in_days: days_until_expiration,
        expired: expired?,
        expires_soon: expires_soon?,
        valid: valid?,
        version: certificate.version,
        signature_algorithm: certificate.signature_algorithm,
        public_key_algorithm: certificate.public_key.class.name,
        key_size: key_size
      }
    end

    def valid?
      return false unless certificate
      !expired? && certificate.not_before <= Time.now
    end

    def expired?
      return false unless certificate
      certificate.not_after < Time.now
    end

    def expires_soon?(days = 30)
      return false unless certificate
      days_until_expiration <= days && !expired?
    end

    def days_until_expiration
      return nil unless certificate
      ((certificate.not_after - Time.now) / 86400).round
    end

    private

    def parse_url(url)
      uri = URI.parse(url)
      uri.scheme = "https" if uri.scheme.nil?
      uri.port = 443 if uri.port.nil?
      uri
    rescue URI::InvalidURIError => e
      raise Error, "Invalid URL: #{url} - #{e.message}"
    end

    def key_size
      case certificate.public_key
      when OpenSSL::PKey::RSA
        certificate.public_key.n.num_bits
      when OpenSSL::PKey::EC
        certificate.public_key.group.degree
      else
        nil
      end
    end
  end
end