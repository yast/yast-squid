#! /usr/bin/env rspec

require_relative "./test_helper"

Yast.import "SquidErrorMessages"
Yast.import "FileUtils"

describe "Yast::SquidErrorMessages" do
  # Use this instead of directly accessing Yast::SquidErrorMessage to ensure the
  # extensive memoization is deleted in every test. That class caches A LOT and
  # offers no method to reset that cache.
  subject do
    obj = Yast::SquidErrorMessagesClass.new
    obj.main
    obj
  end

  before do
    allow(Yast::SCR).to receive(:Read).with(path(".target.dir"), anything)

    allow(Yast::FileUtils).to receive(:IsDirectory) do |name|
      !name.include?("_file")
    end
  end

  describe ".GetLanguages" do
    it "checks the content of /usr/share/squid/errors" do
      expect(Yast::SCR).to receive(:Read).with(path(".target.dir"), subject.err_msg_dir)
      subject.GetLanguages
    end

    context "if error messages path contains directories and plain files" do
      before do
        allow(Yast::SCR).to receive(:Read).with(path(".target.dir"), anything)
          .and_return ["en", "a_file", "ru", "b_file", "uk", "c_file"]
      end

      it "collects the languages with a directory and ignores the plain files" do
        expect(subject.GetLanguages).to contain_exactly("en", "ru", "uk")
      end
    end
  end

  describe ".GetLanguagesToComboBox" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path(".target.dir"), anything)
        .and_return ["en", "a_file", "ru", "rr", "uk", "kk"]
    end

    it "returns an array of item terms" do
      result = subject.GetLanguagesToComboBox
      expect(result).to be_a Array
      expect(result).to all be_a(Yast::Term)
      expect(result.map(&:value)).to all eq(:item)
    end

    it "includes one item with the corresponding label for each known language" do
      result = subject.GetLanguagesToComboBox
      values = result.map { |item| [item.params[0].params[0], item.params[1]] }
      expect(values).to include ["en", "English"]
      expect(values).to include ["ru", "Russian"]
      expect(values).to include ["uk", "Ukrainian"]
    end

    it "includes one item with unprocessed label for each unknown language" do
      result = subject.GetLanguagesToComboBox
      values = result.map { |item| [item.params[0].params[0], item.params[1]] }
      expect(values).to include ["rr", "rr"]
      expect(values).to include ["kk", "kk"]
    end
  end

  describe ".GetPath" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path(".target.dir"), anything)
        .and_return ["en", "ru", "rr"]
    end

    it "returns the full path for languages that are available at the messages path" do
      expect(subject.GetPath("en")).to eq "#{subject.err_msg_dir}/en"
      expect(subject.GetPath("rr")).to eq "#{subject.err_msg_dir}/rr"
    end

    it "returns an empty string for languages not present at the messages path" do
      expect(subject.GetPath("es")).to eq ""
    end
  end

  describe ".GetLanguageFromPath" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path(".target.dir"), anything)
        .and_return ["en", "ru", "rr"]
    end

    it "returns the language string for known paths" do
      expect(subject.GetLanguageFromPath("#{subject.err_msg_dir}/en")).to eq "en"
      expect(subject.GetLanguageFromPath("#{subject.err_msg_dir}/rr")).to eq "rr"
    end

    it "returns nil for non registered paths" do
      expect(subject.GetLanguageFromPath("#{subject.err_msg_dir}/es")).to be_nil
    end
  end
end
