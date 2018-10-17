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

# File:	clients/squid.ycp
# Package:	Configuration of squid
# Summary:	Main file
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: squid.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# Main file for squid configuration. Uses all other files.
module Yast
  class SquidClient < Client
    def main
      Yast.import "UI"

      # **
      # <h3>Configuration of squid</h3>

      textdomain "squid"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Squid module started")

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"

      Yast.import "CommandLine"
      Yast.include self, "squid/wizards.rb"
      @finish = fun_ref(method(:init), "boolean ()")

      @cmdline_description = {
        "id"         => "squid",
        # Command line help text for the Xsquid module
        "help"       => _(
          "Configuration of Squid cache proxy"
        ),
        "guihandler" => fun_ref(method(:SquidSequence), "any ()"),
        "initialize" => fun_ref(method(:init), "boolean ()"),
        "finish"     => @finish,
        "actions"    => {
          "start" => {
            "help"    => "start squid service",
            "handler" => fun_ref(
              method(:startHandler),
              "boolean (map <string, string>)"
            )
          },
          "stop"  => {
            "help"    => "stop squid service",
            "handler" => fun_ref(
              method(:stopHandler),
              "boolean (map <string, string>)"
            )
          }
        },
        "options"    => {},
        "mappings"   => { "start" => [], "stop" => [] }
      }

      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0)
        if Ops.is_path?(WFM.Args(0)) && WFM.Args(0) == path(".propose")
          Builtins.y2milestone("Using PROPOSE mode")
          @propose = true
        end
      end

      # main ui function
      @ret = nil

      @ret = if @propose
        SquidAutoSequence()
      else
        CommandLine.Run(@cmdline_description)
      end
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("Squid module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)

      # EOF
    end

    def startHandler(_options)
      CommandLine.PrintNoCR("Starting service ...  ")
      if Squid.StartService
        CommandLine.Print("Success")
        return true
      else
        CommandLine.Print("Failed")
        return false
      end
    end

    def stopHandler(_options)
      CommandLine.PrintNoCR("Stopping service ...  ")
      if Squid.StopService
        CommandLine.Print("Success")
        return true
      else
        CommandLine.Print("Failed")
        return false
      end
    end

    def init
      true
    end
  end
end

Yast::SquidClient.new.main
