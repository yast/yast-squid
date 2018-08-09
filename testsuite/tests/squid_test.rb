#! /usr/bin/env rspec

require_relative "./test_helper"
require_relative "../../src/modules/Squid"

Yast.import "Squid"

describe "Yast::Squid" do
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
          expect(squid.Write).to be_truthy
        end
      end

      context "and the service is not correctly saved" do
        before do
          allow(service).to receive(:save).and_return(false)
        end

        it "returns false" do
          expect(squid.Write).to be_falsey
        end
      end
    end
  end
end
