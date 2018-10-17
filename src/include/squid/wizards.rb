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

# File:	include/squid/wizards.ycp
# Package:	Configuration of squid
# Summary:	Wizards definitions
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: wizards.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module SquidWizardsInclude
    def initialize_squid_wizards(include_target)
      Yast.import "UI"

      textdomain "squid"

      Yast.import "Sequencer"
      Yast.import "Wizard"
      Yast.import "Label"

      Yast.include include_target, "squid/complex.rb"
    end

    # Main workflow of the squid configuration
    # @return sequence result
    def MainSequence
      aliases = { "main" => -> { MainDialog() } }
      sequence = {
        "ws_start" => "main",
        "main"     => { abort: :abort, next: :next }
      }
      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of squid
    # @return sequence result
    def SquidSequence
      aliases = {
        "read"  => [-> { ReadDialog() }, true],
        "main"  => -> { MainSequence() },
        "write" => [-> { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { abort: :abort, next: "main" },
        "main"     => { abort: :abort, next: "write" },
        "write"    => { abort: :abort, next: :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("squid")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of squid but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def SquidAutoSequence
      # Initialization dialog caption
      caption = _("Squid Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
