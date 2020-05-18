#! /usr/bin/env rspec

require_relative "./test_helper"

Yast.import "Squid"

describe "Yast::Squid" do
  subject(:squid) { Yast::Squid }

  describe "#Write" do
    subject(:squid) { Yast::SquidClass.new }

    before do
      allow(Yast::Progress).to receive(:New)
      allow(Yast::Progress).to receive(:NextStage)
      allow(Yast::Report).to receive(:Error)

      allow(Yast2::SystemService).to receive(:find).with("squid").and_return(service)

      allow(Yast::Mode).to receive(:auto) { auto }
      allow(Yast::Mode).to receive(:commandline) { commandline }

      allow(squid).to receive(:Abort).and_return(false)
      allow(squid).to receive(:writeAllSettings).and_return(settings_written)
      allow(squid).to receive(:writeFirewallSettings).and_return(firewall_settings_written)

      squid.main
    end

    let(:service) { instance_double(Yast2::SystemService, save: true) }

    let(:auto) { false }
    let(:commandline) { false }
    let(:settings_written) { true }
    let(:firewall_settings_written) { true }

    shared_examples "old behavior" do
      before do
        squid.write_only = write_only
        allow(squid).to receive(:IsServiceEnabled).and_return(service_enabled_on_startup)
      end

      let(:write_only) { true }
      let(:service_enabled_on_startup) { true }

      it "does not save the system service" do
        expect(service).to_not receive(:save)

        squid.Write
      end

      context "and service must be enable" do
        it "calls to #EnableService" do
          expect(squid).to receive(:EnableService)

          squid.Write
        end
      end

      context "and service must be disable" do
        let(:service_enabled_on_startup) { false }

        it "calls to #EnableService" do
          expect(squid).to receive(:DisableService)

          squid.Write
        end
      end

      context "and only is writing settings" do
        it "does not call to #StartService" do
          expect(squid).to_not receive(:StartService)

          squid.Write
        end
      end

      context "and not only writing settings" do
        let(:write_only) { false }

        it "calls to #StartService" do
          expect(squid).to receive(:StartService)

          squid.Write
        end
      end
    end

    context "when running in command line" do
      let(:commandline) { true }

      include_examples "old behavior"
    end

    context "when running in AutoYaST mode" do
      let(:auto) { true }

      include_examples "old behavior"
    end

    context "when running in normal mode" do
      it "does not call to #EnableService nor #DisableService" do
        expect(squid).to_not receive(:EnableService)
        expect(squid).to_not receive(:Disableervice)

        squid.Write
      end

      it "does not call to #StartService" do
        expect(squid).to_not receive(:StartService)

        squid.Write
      end

      it "saves the system service" do
        expect(service).to receive(:save)

        squid.Write
      end

      context "and the service is correctly saved" do
        before do
          allow(service).to receive(:save).and_return(true)
        end

        it "returns true" do
          expect(squid.Write).to eq(true)
        end
      end

      context "and the service is not correctly saved" do
        before do
          allow(service).to receive(:save).and_return(false)
        end

        it "returns false" do
          expect(squid.Write).to eq(false)
        end
      end
    end
  end

  describe ".readHttpPorts" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path_matching(/\.squid\..*http_port/))
        .and_return [["localhost:3128"], ["80", "transparent"]]
    end

    it "reads the ports in different supported formats" do
      squid.readHttpPorts
      expect(squid.http_ports).to eq [
        { "host" => "localhost", "port" => "3128" },
        { "host" => "", "port" => "80", "transparent" => true }
      ]
    end
  end

  describe ".readHttpAccesses" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path_matching(/\.squid\..*http_access/))
        .and_return [
          ["allow", "manager", "localhost"], ["deny", "manager"], ["deny", "!Safe_ports"],
          ["deny", "CONNECT", "!SSL_ports"], ["allow", "localhost"],
          ["allow", "localhost_public"], ["deny", "all"]
        ]
    end

    it "reads entries in several formats" do
      squid.readHttpAccesses
      expect(squid.http_accesses).to eq [
        { "acl" => ["manager", "localhost"],  "allow" => true },
        { "acl" => ["manager"],               "allow" => false },
        { "acl" => ["!Safe_ports"],           "allow" => false },
        { "acl" => ["CONNECT", "!SSL_ports"], "allow" => false },
        { "acl" => ["localhost"],             "allow" => true },
        { "acl" => ["localhost_public"],      "allow" => true },
        { "acl" => ["all"],                   "allow" => false }
      ]
    end
  end

  describe ".readRefreshPatterns" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path_matching(/\.squid\..*refresh_pattern/))
        .and_return [
          ["^ftp:", "1440", "20%", "10080"],
          ["-i", "^gopher:", "1440", "0%", "1440"],
          [".", "0", "20%", "4320"]
        ]
    end

    it "parses several kinds of patterns" do
      squid.readRefreshPatterns
      expect(squid.refresh_patterns).to eq [
        {
          "case_sensitive" => true, "max" => "10080", "min" => "1440",
          "percent" => "20", "regexp" => "^ftp:"
        },
        {
          "case_sensitive" => false, "max" => "1440", "min" => "1440",
          "percent" => "0", "regexp" => "^gopher:"
        },
        {
          "case_sensitive" => true, "max" => "4320", "min" => "0",
          "percent" => "20", "regexp" => "."
        }
      ]
    end
  end

  describe ".readACLs" do
    before do
      allow(Yast::SCR).to receive(:Read).with(path_matching(/\.squid\..*acl/))
        .and_return [
          ["QUERY", "urlpath_regex", "cgi-bin", "\\?"],
          ["apache", "rep_header", "Server", "^Apache"],
          ["all", "src", "0.0.0.0/0.0.0.0"],
          ["manager", "proto", "cache_object"],
          ["localhost", "src", "127.0.0.1/255.255.255.255"],
          ["localhost_public", "src", "10.20.1.241/255.255.255.255"],
          ["to_localhost", "dst", "127.0.0.0/8"], ["SSL_ports", "port", " 443"],
          ["Safe_ports", "port", "80"], ["Safe_ports", "port", "21"],
          ["Safe_ports", "port", "443"], ["Safe_ports", "port", "70"],
          ["Safe_ports", "port", "210"], ["Safe_ports", "port", "1025-65535"],
          ["Safe_ports", "port", "280"], ["Safe_ports", "port", "488"],
          ["Safe_ports", "port", "591"], ["Safe_ports", "port", "777"],
          ["CONNECT", "method", "CONNECT"]
        ]
    end

    it "parses all kind of supported ACL formats" do
      squid.readACLs
      expect(squid.acls).to eq [
        { "name" => "QUERY", "options" => ["cgi-bin \\?"], "type" => "urlpath_regex" },
        { "name" => "apache", "options" => ["Server", "^Apache"], "type" => "rep_header" },
        { "name" => "all", "options" => ["0.0.0.0/0.0.0.0"], "type" => "src" },
        { "name" => "manager", "options" => ["cache_object"], "type" => "proto" },
        { "name" => "localhost", "options" => ["127.0.0.1/255.255.255.255"], "type" => "src" },
        {
          "name" => "localhost_public", "options" => ["10.20.1.241/255.255.255.255"],
          "type" => "src"
        },
        { "name" => "to_localhost", "options" => ["127.0.0.0/8"], "type" => "dst" },
        { "name" => "SSL_ports", "options" => [" 443"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["80"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["21"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["443"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["70"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["210"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["1025-65535"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["280"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["488"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["591"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["777"], "type" => "port" },
        { "name" => "CONNECT", "options" => ["CONNECT"], "type" => "method" }
      ]
    end
  end

  describe ".readACLs" do
    def mock_squid_conf(attr, values)
      allow(Yast::SCR).to receive(:Read).with(path_matching(/\.squid\..*#{attr}\"$/))
        .and_return [*values]
    end

    before do
      mock_squid_conf("access_log", ["/var/log/squid/access.log"])
      mock_squid_conf("cache_dir", ["ufs", "/var/cache/squid", "100", "16", "256"])
      mock_squid_conf("cache_log", ["/var/log/squid/cache.log"])
      mock_squid_conf("cache_mem", ["80", "MB"])
      mock_squid_conf("cache_mgr", ["webmaster"])
      mock_squid_conf("cache_replacement_policy", ["lru"])
      mock_squid_conf("cache_store_log", ["/var/log/squid/store.log"])
      mock_squid_conf("cache_swap_high", ["95"])
      mock_squid_conf("cache_swap_low", ["90"])
      mock_squid_conf("client_lifetime", ["1", "day"])
      mock_squid_conf("connect_timeout", ["2", "minutes"])
      mock_squid_conf("error_directory", ["/usr/share/squid/errors/English"])
      mock_squid_conf("ftp_passive", ["on"])
      mock_squid_conf("maximum_object_size", ["4096", "KB"])
      mock_squid_conf("memory_replacement_policy", ["heap", "GDSF"])
      mock_squid_conf("minimum_object_size", ["0", "KB"])
    end

    it "reads all the known settings" do
      squid.readRestSetting
      expect(squid.settings).to eq(
        "access_log"                => ["/var/log/squid/access.log"],
        "cache_dir"                 => ["ufs", "/var/cache/squid", "100", "16", "256"],
        "cache_log"                 => ["/var/log/squid/cache.log"],
        "cache_mem"                 => ["8", "MB"],
        "cache_mgr"                 => ["webmaster"],
        "cache_replacement_policy"  => ["lru"],
        "cache_store_log"           => ["/var/log/squid/store.log"],
        "cache_swap_high"           => ["95"],
        "cache_swap_low"            => ["90"],
        "client_lifetime"           => ["1", "days"],
        "connect_timeout"           => ["2", "minutes"],
        "error_directory"           => ["/usr/share/squid/errors/en"],
        "ftp_passive"               => ["on"],
        "maximum_object_size"       => ["4096", "KB"],
        "memory_replacement_policy" => ["lru"],
        "minimum_object_size"       => ["0", "KB"]
      )
    end
  end

  describe ".Read" do
    before do
      allow(Yast::Progress).to receive(:New)
      allow(Yast::Progress).to receive(:NextStage)
      allow(Yast::Progress).to receive(:set)
      allow(Yast::Service).to receive(:Enabled)
      allow(Y2Firewall::Firewalld.instance).to receive(:read).and_return true
    end

    it "relies on all the partial readers" do
      expect(squid).to receive(:readHttpPorts).and_return true
      expect(squid).to receive(:readHttpAccesses).and_return true
      expect(squid).to receive(:readRefreshPatterns).and_return true
      expect(squid).to receive(:readACLs).and_return true
      expect(squid).to receive(:readRestSetting).and_return true
      squid.Read
    end

    it "fallbacks to the default values" do
      allow(Yast::SCR).to receive(:Read).with(path_matching(/\.squid\..*$/)).and_return nil

      squid.Read

      expect(squid.settings["cache_mem"]).to eq squid.parameters["cache_mem"]
      expect(squid.settings["memory_replacement_policy"])
        .to eq squid.parameters["memory_replacement_policy"]
    end
  end
end
