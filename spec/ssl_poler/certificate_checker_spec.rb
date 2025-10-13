require "spec_helper"

RSpec.describe SslPoler::CertificateChecker do
  describe "#initialize" do
    it "accepts a URL" do
      checker = described_class.new("https://example.com")
      expect(checker.url).to eq("https://example.com")
    end
  end

  describe "#check" do
    context "with a valid SSL site" do
      it "successfully retrieves certificate information" do
        checker = described_class.new("https://www.google.com")
        result = checker.check

        expect(result).to be true
        expect(checker.certificate).not_to be_nil
        expect(checker.error).to be_nil
      end
    end

    context "with an invalid host" do
      it "handles errors gracefully" do
        checker = described_class.new("https://thisdoesnotexist12345.com")
        result = checker.check

        expect(result).to be false
        expect(checker.error).not_to be_nil
      end
    end
  end

  describe "#certificate_info" do
    it "returns comprehensive certificate information" do
      checker = described_class.new("https://www.google.com")
      checker.check

      info = checker.certificate_info

      expect(info).to be_a(Hash)
      expect(info[:subject]).to be_a(String)
      expect(info[:issuer]).to be_a(String)
      expect(info[:not_before]).to be_a(Time)
      expect(info[:not_after]).to be_a(Time)
      expect(info[:expires_in_days]).to be_a(Integer)
      expect([true, false]).to include(info[:expired])
      expect([true, false]).to include(info[:valid])
    end
  end

  describe "#expired?" do
    it "returns false for valid certificate" do
      checker = described_class.new("https://www.google.com")
      checker.check

      expect(checker.expired?).to be false
    end
  end

  describe "#valid?" do
    it "returns true for valid certificate" do
      checker = described_class.new("https://www.google.com")
      checker.check

      expect(checker.valid?).to be true
    end
  end

  describe "#days_until_expiration" do
    it "returns positive number for valid certificate" do
      checker = described_class.new("https://www.google.com")
      checker.check

      days = checker.days_until_expiration
      expect(days).to be > 0
    end
  end
end