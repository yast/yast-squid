#! /usr/bin/env rspec

require_relative "./test_helper"

Yast.import "SquidACL"

describe "Yast::SquidACL" do
  subject { Yast::SquidACL }

  let(:acls) do
    [
      "arp", "browser", "dst", "dstdom_regex", "dstdomain", "maxconn", "method",
      "myip", "myport", "port", "proto", "referer_regex", "rep_header", "rep_mime_type",
      "req_header", "req_mime_type", "src", "srcdom_regex", "srcdomain", "time",
      "url_regex", "urlpath_regex"
    ]
  end

  describe ".SupportedACLs" do
    it "returns the full list of ACLs" do
      expect(subject.SupportedACLs).to contain_exactly(*acls)
    end
  end

  describe ".GetTypesToComboBox" do
    it "returns an array of item terms" do
      result = subject.GetTypesToComboBox
      expect(result).to be_a Array
      expect(result).to all be_a(Yast::Term)
      expect(result.map(&:value)).to all eq(:item)
    end

    it "includes one item per each ACL" do
      result = subject.GetTypesToComboBox
      values = result.map { |item| item.params[1] }
      expect(values).to contain_exactly(*acls)
    end
  end
end
