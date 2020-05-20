#! /usr/bin/env rspec

require_relative "./test_helper"
require_relative "../src/include/squid/complex"

Yast.import "Confirm"
Yast.import "Squid"
Yast.import "Wizard"
Yast.import "PackageSystem"

describe "Yast::SquidComplexInclude" do
  # Dummy class to test the include
  class TestSquidClient < Yast::Client
    include Yast::SquidComplexInclude

    def initialize
      initialize_squid_complex(self)
    end

  private

    def load_widgets; end

    def load_screens; end
  end

  describe "#ReadDialog" do
    subject(:squid_client) { TestSquidClient.new }

    let(:root_privileges) { true }
    let(:squid_installed) { true }
    let(:squid_read) { true }

    before do
      allow(Yast::Wizard).to receive(:RestoreHelp)
      allow(Yast::Squid).to receive(:AbortFunction)
      allow(Yast::Confirm).to receive(:MustBeRoot).and_return(root_privileges)
      allow(Yast::PackageSystem).to receive(:CheckAndInstallPackages).with(["squid"]).and_return(squid_installed)
      allow(Yast::Squid).to receive(:Read).and_return(squid_read)
    end

    context "when executed without root privileges" do
      let(:root_privileges) { false }

      it "returns :abort" do
        expect(squid_client.ReadDialog).to be(:abort)
      end
    end

    context "when squid system is not installed" do
      let(:squid_installed) { false }

      it "returns :abort" do
        expect(squid_client.ReadDialog).to be(:abort)
      end
    end

    context "when Squid cannot be read" do
      let(:squid_read) { false }

      it "returns :abort" do
        expect(squid_client.ReadDialog).to be(:abort)
      end
    end

    context "when all requirements are accomplished" do
      let(:service) { instance_double(Yast2::Systemd::Service) }
      let(:service_widget) { instance_double(CWM::ServiceWidget, cwm_definition: {}) }

      before do
        allow(Yast::Squid).to receive(:service).and_return(service)
        allow(::CWM::ServiceWidget).to receive(:new).and_return(service_widget)
      end

      it "load the service widget" do
        expect(::CWM::ServiceWidget).to receive(:new).with(service)

        squid_client.ReadDialog
      end

      it "returns :next" do
        expect(squid_client.ReadDialog).to be(:next)
      end
    end
  end
end
