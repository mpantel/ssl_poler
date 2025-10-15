require "spec_helper"
require "stringio"

RSpec.describe SslPoler::CLI do
  let(:valid_results) do
    [
      {
        name: "Example",
        url: "https://example.com",
        not_after: Time.new(2025, 12, 31),
        expired: false,
        expires_soon: false
      },
      {
        name: "Google",
        url: "https://google.com",
        not_after: Time.new(2025, 11, 15),
        expired: false,
        expires_soon: true
      },
      {
        name: "Expired Site",
        url: "https://expired.com",
        not_after: Time.new(2024, 1, 1),
        expired: true,
        expires_soon: false
      },
      {
        name: "Error Site",
        url: "https://error.com",
        error: "Connection refused"
      }
    ]
  end

  describe "#display_summary_table" do
    it "displays a formatted table with all URLs" do
      cli = described_class.new([])
      output = StringIO.new

      expect {
        cli.send(:display_summary_table, valid_results)
      }.to output.to_stdout

      # Capture the actual output
      output_string = capture_stdout do
        cli.send(:display_summary_table, valid_results)
      end

      # Verify table contains headers
      expect(output_string).to include("Name")
      expect(output_string).to include("URL")
      expect(output_string).to include("Status")
      expect(output_string).to include("Expiry Date")

      # Verify table contains data
      expect(output_string).to include("Example")
      expect(output_string).to include("https://example.com")
      expect(output_string).to include("OK")
      expect(output_string).to include("2025-12-31")

      expect(output_string).to include("Google")
      expect(output_string).to include("WARNING")
      expect(output_string).to include("2025-11-15")

      expect(output_string).to include("Expired Site")
      expect(output_string).to include("EXPIRED")
      expect(output_string).to include("2024-01-01")

      expect(output_string).to include("Error Site")
      expect(output_string).to include("ERROR")
      expect(output_string).to include("N/A")
    end

    it "handles long URLs and names by truncating" do
      long_results = [
        {
          name: "A" * 50,
          url: "https://example.com/" + "path/" * 20,
          not_after: Time.new(2025, 12, 31),
          expired: false,
          expires_soon: false
        }
      ]

      cli = described_class.new([])
      output_string = capture_stdout do
        cli.send(:display_summary_table, long_results)
      end

      # Verify truncation occurred (should contain ...)
      expect(output_string).to include("...")
    end

    it "handles empty results array" do
      cli = described_class.new([])

      expect {
        cli.send(:display_summary_table, [])
      }.not_to raise_error
    end
  end

  describe "#display_summary" do
    it "includes summary statistics and table" do
      cli = described_class.new([])
      output_string = capture_stdout do
        cli.send(:display_summary, valid_results)
      end

      # Verify summary statistics
      expect(output_string).to include("Summary:")
      expect(output_string).to include("Total:")
      expect(output_string).to include("OK:")
      expect(output_string).to include("Expiring Soon:")
      expect(output_string).to include("Expired:")
      expect(output_string).to include("Errors:")

      # Verify table is also included
      expect(output_string).to include("Name")
      expect(output_string).to include("Status")
      expect(output_string).to include("Expiry Date")
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end