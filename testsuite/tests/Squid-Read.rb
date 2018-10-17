# encoding: utf-8

module Yast
  class SquidReadClient < Client
    def main
      # testedfiles: Squid.ycp

      @READ = {
        "squid" => {
          "http_port"                 => [
            ["localhost:3128"],
            ["80", "transparent"]
          ],
          "acl"                       => [
            ["QUERY", "urlpath_regex", "cgi-bin", "\\?"],
            ["apache", "rep_header", "Server", "^Apache"],
            ["all", "src", "0.0.0.0/0.0.0.0"],
            ["manager", "proto", "cache_object"],
            ["localhost", "src", "127.0.0.1/255.255.255.255"],
            ["localhost_public", "src", "10.20.1.241/255.255.255.255"],
            ["to_localhost", "dst", "127.0.0.0/8"],
            ["SSL_ports", "port", " 443"],
            ["Safe_ports", "port", "80"],
            ["Safe_ports", "port", "21"],
            ["Safe_ports", "port", "443"],
            ["Safe_ports", "port", "70"],
            ["Safe_ports", "port", "210"],
            ["Safe_ports", "port", "1025-65535"],
            ["Safe_ports", "port", "280"],
            ["Safe_ports", "port", "488"],
            ["Safe_ports", "port", "591"],
            ["Safe_ports", "port", "777"],
            ["CONNECT", "method", "CONNECT"]
          ],
          "http_access"               => [
            ["allow", "manager", "localhost"],
            ["deny", "manager"],
            ["deny", "!Safe_ports"],
            ["deny", "CONNECT", "!SSL_ports"],
            ["allow", "localhost"],
            ["allow", "localhost_public"],
            ["deny", "all"]
          ],
          "refresh_pattern"           => [
            ["^ftp:", "1440", "20%", "10080"],
            ["-i", "^gopher:", "1440", "0%", "1440"],
            [".", "0", "20%", "4320"]
          ],
          "cache_dir"                 => [
            ["ufs", "/var/cache/squid", "100", "16", "256"]
          ],
          "cache_mem"                 => [["80", "MB"]],
          "cache_swap_low"            => [["90"]],
          "cache_swap_high"           => [["95"]],
          "maximum_object_size"       => [["4096", "KB"]],
          "minimum_object_size"       => [["0", "KB"]],
          "cache_replacement_policy"  => [["lru"]],
          "memory_replacement_policy" => [["heap", "GDSF"]],
          "access_log"                => [["/var/log/squid/access.log"]],
          "cache_log"                 => [["/var/log/squid/cache.log"]],
          "cache_store_log"           => [["/var/log/squid/store.log"]],
          "cache_swap_log"            => [["none"]],
          "connect_timeout"           => [["2", "minutes"]],
          "client_lifetime"           => [["1", "day"]],
          "error_directory"           => [["/usr/share/squid/errors/English"]],
          "cache_mgr"                 => [["webmaster"]],
          "ftp_passive"               => [["on"]]
        }
      }
      @READ = { "etc" => @READ }

      @WRITE = {}
      @EXECUTE = {
        "target" => {
          "bash_output" => {
            "exit"   => 0,
            "stdout" => "",
            "stderr" => ""
          }
        }
      }

      Yast.include self, "testsuite.rb"
      # TESTSUITE_INIT([READ,WRITE,EXECUTE], nil);

      Yast.import "Squid"

      DUMP("Squid::readHttpPorts()")
      TEST(-> { Squid.readHttpPorts }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP("Squid::http_ports")
      TEST(-> { Squid.http_ports }, [], nil)

      DUMP("------------------------------")

      DUMP("Squid::readHttpAccesses()")
      TEST(-> { Squid.readHttpAccesses }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP("Squid::http_accesses")
      TEST(-> { Squid.http_accesses }, [], nil)

      DUMP("------------------------------")

      DUMP("Squid::readRefreshPatterns()")
      TEST(-> { Squid.readRefreshPatterns }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP("Squid::refresh_patterns")
      TEST(-> { Squid.refresh_patterns }, [], nil)

      DUMP("------------------------------")

      DUMP("Squid::readACLs()")
      TEST(-> { Squid.readACLs }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP("Squid::acls")
      TEST(-> { Squid.acls }, [], nil)

      DUMP("------------------------------")

      DUMP("Squid::readRestSetting()")
      TEST(-> { Squid.readRestSetting }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP("Squid::settings")
      TEST(-> { Squid.settings }, [], nil)

      DUMP("------------------------------")

      DUMP("Squid::Read()")
      TEST(-> { Squid.Read }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP("Squid::settings")
      TEST(-> { Squid.settings }, [], nil)
      DUMP("Squid::acls")
      TEST(-> { Squid.acls }, [], nil)
      DUMP("Squid::refresh_patterns")
      TEST(-> { Squid.refresh_patterns }, [], nil)
      DUMP("Squid::http_accesses")
      TEST(-> { Squid.http_accesses }, [], nil)
      DUMP("Squid::http_ports")
      TEST(-> { Squid.http_ports }, [], nil)

      # Testing of using default values:
      DUMP("------------------------------")
      DUMP("----testing defualt values----")
      @READ = Ops.get_map(@READ, "etc", {})
      Ops.set(
        @READ,
        "squid",
        Builtins.remove(Ops.get_map(@READ, "squid", {}), "cache_mem")
      )
      Ops.set(
        @READ,
        "squid",
        Builtins.remove(
          Ops.get_map(@READ, "squid", {}),
          "memory_replacement_policy"
        )
      )
      @READ = { "etc" => @READ }

      DUMP("Squid:Read()")
      TEST(-> { Squid.Read }, [@READ, @WRITE, @EXECUTE], nil)

      DUMP(
        "Squid::settings[\"cache_mem\"]:[\"1\"] == Squid::parameters[\"cache_mem\"]:[\"2\"]"
      )
      TEST(lambda do
        Convert.convert(
          Ops.get(Squid.settings, "cache_mem") { ["1"] },
          from: "any",
          to:   "list <string>"
        ) ==
          Ops.get(Squid.parameters, "cache_mem") { ["2"] }
      end, [], nil)

      DUMP(
        "Squid::settings[\"memory_replacement_policy\"]:[\"1\"] == Squid::parameters[\"memory_replacement_memory\"]:[\"2\"]"
      )
      TEST(lambda do
        Convert.convert(
          Ops.get(Squid.settings, "memory_replacement_policy") { ["1"] },
          from: "any",
          to:   "list <string>"
        ) ==
          Ops.get(Squid.parameters, "memory_replacement_policy") { ["2"] }
      end, [], nil)

      nil
    end
  end
end

Yast::SquidReadClient.new.main
