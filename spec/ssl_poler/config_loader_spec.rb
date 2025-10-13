require "spec_helper"
require "tempfile"

RSpec.describe SslPoler::ConfigLoader do
  let(:valid_config) do
    {
      "urls" => [
        "https://example.com",
        { "name" => "Google", "url" => "https://google.com" }
      ]
    }
  end

  describe "#load" do
    context "with valid config file" do
      it "loads configuration successfully" do
        file = Tempfile.new(["config", ".yml"])
        file.write(YAML.dump(valid_config))
        file.close

        loader = described_class.new(file.path)
        loader.load

        expect(loader.urls).to be_an(Array)
        expect(loader.urls.size).to eq(2)
        expect(loader.urls[0][:url]).to eq("https://example.com")
        expect(loader.urls[1][:name]).to eq("Google")

        file.unlink
      end
    end

    context "with non-existent file" do
      it "raises error" do
        loader = described_class.new("/nonexistent/path.yml")
        expect { loader.load }.to raise_error(SslPoler::Error, /not found/)
      end
    end

    context "with invalid YAML" do
      it "raises error" do
        file = Tempfile.new(["config", ".yml"])
        file.write("invalid: yaml: content: [")
        file.close

        loader = described_class.new(file.path)
        expect { loader.load }.to raise_error(SslPoler::Error, /Invalid YAML/)

        file.unlink
      end
    end

    context "with missing urls key" do
      it "raises error" do
        file = Tempfile.new(["config", ".yml"])
        file.write(YAML.dump({ "other" => "data" }))
        file.close

        loader = described_class.new(file.path)
        expect { loader.load }.to raise_error(SslPoler::Error, /must contain 'urls'/)

        file.unlink
      end
    end

    context "with empty urls array" do
      it "raises error" do
        file = Tempfile.new(["config", ".yml"])
        file.write(YAML.dump({ "urls" => [] }))
        file.close

        loader = described_class.new(file.path)
        expect { loader.load }.to raise_error(SslPoler::Error, /cannot be empty/)

        file.unlink
      end
    end
  end
end