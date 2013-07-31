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

# File:	include/squid/helper_functions.ycp
# Package:	Configuration of squid
# Summary:	Helper functions for various situations.
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: dialogs.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module SquidHelperFunctionsInclude
    def initialize_squid_helper_functions(include_target)
      textdomain "squid"

      Yast.import "FileUtils"
    end

    # Returns a widget with setting of units
    def sizeUnitWidget(id)
      ComboBox(Id(id), _("&Units"), [Item("KB"), Item("MB")])
    end

    # Returns multiple which equals to given parameter.
    def unitToMultiple(unit)
      return 1024 if unit == "KB"
      return 1024 * 1024 if unit == "MB"

      nil
    end


    # Returns a widget with setting of units
    def timeUnitWidget(id)
      ComboBox(
        Id(id),
        " ",
        [
          Item(Id("seconds"), _("seconds")),
          Item(Id("minutes"), _("minutes")),
          Item(Id("hours"), _("hours")),
          Item(Id("days"), _("days"))
        ]
      )
    end


    def isCorrectPathnameOfLogFile(str)
      ok = Builtins.regexpmatch(str, "^/([^/]+/)*[^/]+$")
      if ok
        dir = Builtins.regexptokenize(str, "^(.+)/[^/]+$")
        ok = false if !FileUtils.IsDirectory(Ops.get(dir, 0, "/"))
      end
      ok
    end

    def isIPAddr(str)
      ok = true
      l = Builtins.regexptokenize(
        str,
        "^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)$"
      )

      if Builtins.size(l) != 4
        ok = false
      else
        i = 0
        Builtins.foreach(l) do |value|
          i = Builtins.tointeger(value)
          if Ops.less_than(i, 0) || Ops.greater_than(i, 255)
            ok = false
            raise Break
          end
        end
      end

      ok
    end

    def isHostName(str)
      #max 22 chars length
      #see http://www.no-ip.com/support/faq/EN/dynamic_ddns/what_is_a_valid_hostname.html
      Builtins.regexpmatch(str, "^[a-zA-Z0-9][a-zA-Z0-9-]{0,21}$")
    end

    def isCorrectHost(host)
      return false if !isIPAddr(host) && !isHostName(host)
      true
    end
  end
end
