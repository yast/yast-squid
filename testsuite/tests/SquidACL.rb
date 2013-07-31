# encoding: utf-8

module Yast
  class SquidACLClient < Client
    def main
      # testedfiles: SquidACL.ycp
      @READ = {
        "squid" => {
          "acl"         => [
            "QUERY urlpath_regex cgi-bin \\?",
            "apache rep_header Server ^Apache",
            "all src 0.0.0.0/0.0.0.0",
            "manager proto cache_object",
            "localhost src  \t  \t 127.0.0.1/255.255.255.255",
            "localhost_public src 10.20.1.241/255.255.255.255",
            "to_localhost dst 127.0.0.0/8",
            "SSL_ports port  443",
            "Safe_ports port 80",
            "Safe_ports port 21",
            "Safe_ports port    443",
            "Safe_ports port 70",
            "Safe_ports port 210",
            "Safe_ports port 1025-65535",
            "Safe_ports port 280",
            "Safe_ports port 488",
            "Safe_ports port 591",
            "Safe_ports port 777",
            "CONNECT method CONNECT"
          ],
          "http_access" => [
            "allow manager localhost",
            "deny manager",
            "deny !Safe_ports",
            "deny CONNECT  !SSL_ports",
            "allow localhost",
            "allow  localhost_public",
            "deny all"
          ]
        }
      }

      @WRITE = {}
      @EXECUTE = {}

      Yast.include self, "testsuite.rb"
      #TESTSUITE_INIT([READ,WRITE,EXECUTE], nil);

      Yast.import "SquidACL"

      DUMP("SupportedACLs()")
      TEST(lambda { SquidACL.SupportedACLs }, [], nil)
      DUMP("GetTypesToComboBox()")
      TEST(lambda { SquidACL.GetTypesToComboBox }, [], nil)

      nil
    end
  end
end

Yast::SquidACLClient.new.main
