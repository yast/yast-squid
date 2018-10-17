# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	clients/squid_auto.ycp
# Package:	Configuration of squid
# Summary:	Client for autoinstallation
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: squid_auto.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of squid settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("squid_auto", [ "Summary", mm ]);
module Yast
  class SquidAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "squid"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Squid auto started")

      Yast.import "Squid"
      Yast.include self, "squid/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      Squid.SetDefaultValues if !Squid.GetModified

      # Create a summary
      if @func == "Summary"
        @ret = Ops.get_string(Squid.Summary, 0, "")
      # Reset configuration
      elsif @func == "Reset"
        Squid.Import({})
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = SquidAutoSequence()
        Squid.SetModified if @ret != :abort && @ret != :cancel
      # Import configuration
      elsif @func == "Import"
        @ret = Squid.Import(@param)
      # Return actual state
      elsif @func == "Export"
        @ret = Squid.Export
      # Return needed packages
      elsif @func == "Packages"
        @ret = Squid.AutoPackages
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        @ret = Squid.Read
        Progress.set(@progress_orig)
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        Squid.write_only = true
        @ret = Squid.Write
        Progress.set(@progress_orig)
      elsif @func == "SetModified"
        Squid.SetModified
        @ret = true
      elsif @func == "GetModified"
        @ret = Squid.GetModified
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Squid auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)

      # EOF
    end
  end
end

Yast::SquidAutoClient.new.main
