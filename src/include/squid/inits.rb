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

# File:	include/squid/inits.ycp
# Package:	Configuration of squid
# Summary:	All Init... functions for dialogs.
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id$
module Yast
  module SquidInitsInclude
    def initialize_squid_inits(include_target)
      Yast.import "UI"

      textdomain "squid"

      Yast.import "Squid"
      Yast.import "SquidACL"
      Yast.import "SquidErrorMessages"


      Yast.include include_target, "squid/helps.rb"
    end

    # Do simple initialization of dialog.
    # Given map has to be in form:
    #      $[ id_of_widget : value_on_which_has_to_be_set,
    #         ....
    #       ]
    def simpleInit(m)
      m = deep_copy(m)
      Builtins.foreach(m) do |key, value|
        UI.ChangeWidget(Id(key), :Value, value)
      end

      nil
    end




    #*******************  HTTP_PORT  ****************
    def InitHttpPortsTable(key)
      items = []
      i = 0

      Builtins.foreach(Squid.GetHttpPorts) do |value|
        items = Builtins.add(
          items,
          Item(
            Id(i),
            Ops.get_string(value, "host", ""),
            Ops.get_string(value, "port", ""),
            # table cell
            Ops.get_boolean(value, "transparent", false) ? _("Transparent") : ""
          )
        )
        i = Ops.add(i, 1)
      end

      Builtins.y2debug(
        "complex::InitPortsTable() - items: %1, http_ports: %2",
        items,
        Squid.GetHttpPorts
      )
      UI.ChangeWidget(Id("http_port"), :Items, items)
      if Ops.greater_than(Builtins.size(items), 0)
        UI.ChangeWidget(Id(:edit), :Enabled, true)
        UI.ChangeWidget(Id(:del), :Enabled, true)
      else
        UI.ChangeWidget(Id(:edit), :Enabled, false)
        UI.ChangeWidget(Id(:del), :Enabled, false)
      end

      nil
    end
    def InitAddEditHttpPortDialog(id_item)
      if id_item != nil
        values = Squid.GetHttpPort(id_item)

        UI.ChangeWidget(Id("host"), :Value, Ops.get_string(values, "host", ""))
        UI.ChangeWidget(Id("port"), :Value, Ops.get_string(values, "port", ""))
        UI.ChangeWidget(
          Id("transparent"),
          :Value,
          Ops.get_boolean(values, "transparent", false)
        )
      end

      nil
    end
    #*******************  HTTP_PORT END  ************



    #****************  REFRESH_PATTERNS  ************
    def InitRefreshPatternsTable(key)
      items = []
      i = 0

      Builtins.foreach(Squid.GetRefreshPatterns) do |value|
        items = Builtins.add(
          items,
          Item(
            Id(i),
            Ops.get_string(value, "regexp", ""),
            Ops.get_string(value, "min", ""),
            Ops.get_string(value, "percent", ""),
            Ops.get_string(value, "max", "")
          )
        )
        i = Ops.add(i, 1)
      end

      Builtins.y2debug("complex::InitRefreshPatternsTable() - items: %1", items)
      UI.ChangeWidget(Id("refresh_patterns"), :Items, items)
      if Ops.greater_than(Builtins.size(items), 0)
        UI.ChangeWidget(Id(:edit), :Enabled, true)
        UI.ChangeWidget(Id(:del), :Enabled, true)
        UI.ChangeWidget(Id(:up), :Enabled, true)
        UI.ChangeWidget(Id(:down), :Enabled, true)
      else
        UI.ChangeWidget(Id(:edit), :Enabled, false)
        UI.ChangeWidget(Id(:del), :Enabled, false)
        UI.ChangeWidget(Id(:up), :Enabled, false)
        UI.ChangeWidget(Id(:down), :Enabled, false)
      end

      nil
    end
    def InitAddEditRefreshPatternDialog(id_item)
      if id_item != nil
        values = Squid.GetRefreshPattern(id_item)

        UI.ChangeWidget(
          Id("regexp"),
          :Value,
          Ops.get_string(values, "regexp", "")
        )
        UI.ChangeWidget(
          Id("min"),
          :Value,
          Builtins.tointeger(Ops.get_string(values, "min", ""))
        )
        UI.ChangeWidget(
          Id("percent"),
          :Value,
          Builtins.tointeger(Ops.get_string(values, "percent", ""))
        )
        UI.ChangeWidget(
          Id("max"),
          :Value,
          Builtins.tointeger(Ops.get_string(values, "max", ""))
        )
        UI.ChangeWidget(
          Id("regexp_case_insensitive"),
          :Value,
          !Ops.get_boolean(values, "case_sensitive", true)
        )

        Builtins.y2debug(
          "complex::InitAddEditRefreshPatternDialog() - values: %1",
          values
        )
      end

      nil
    end
    #****************  REFRESH_PATTERNS END  ********


    #****************  CACHE DIALOG  ****************
    def InitCache2Dialog(key)
      set = Convert.convert(
        Squid.GetSettings,
        :from => "map <string, any>",
        :to   => "map <string, list>"
      )
      simpleInit(
        {
          "cache_mem"                   => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "cache_mem", []), 0, "")
          ),
          "cache_mem_units"             => Ops.get_string(
            Ops.get(set, "cache_mem", []),
            1,
            ""
          ),
          "cache_max_object_size"       => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "maximum_object_size", []), 0, "")
          ),
          "cache_max_object_size_units" => Ops.get_string(
            Ops.get(set, "maximum_object_size", []),
            1,
            ""
          ),
          "cache_min_object_size"       => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "minimum_object_size", []), 0, "")
          ),
          "cache_min_object_size_units" => Ops.get_string(
            Ops.get(set, "minimum_object_size", []),
            1,
            ""
          ),
          "cache_swap_low"              => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "cache_swap_low", []), 0, "")
          ),
          "cache_swap_high"             => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "cache_swap_high", []), 0, "")
          ),
          "cache_replacement_policy"    => Ops.get_string(
            Ops.get(set, "cache_replacement_policy", []),
            0,
            ""
          ),
          "memory_replacement_policy"   => Ops.get_string(
            Ops.get(set, "memory_replacement_policy", []),
            0,
            ""
          )
        }
      )
      UI.ChangeWidget(Id("cache_max_object_size"), :Notify, true)
      UI.ChangeWidget(Id("cache_min_object_size"), :Notify, true)
      UI.ChangeWidget(Id("cache_max_object_size_units"), :Notify, true)
      UI.ChangeWidget(Id("cache_min_object_size_units"), :Notify, true)

      UI.ChangeWidget(Id("cache_swap_low"), :Notify, true)
      UI.ChangeWidget(Id("cache_swap_high"), :Notify, true)

      nil
    end

    def InitCacheDirectoryDialog(key)
      set = Convert.convert(
        Squid.GetSettings,
        :from => "map <string, any>",
        :to   => "map <string, list>"
      )
      simpleInit(
        {
          "cache_dir" => Ops.get_string(Ops.get(set, "cache_dir", []), 1, ""),
          "mbytes"    => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "cache_dir", []), 2, "")
          ),
          "l1dirs"    => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "cache_dir", []), 3, "")
          ),
          "l2dirs"    => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "cache_dir", []), 4, "")
          )
        }
      )

      nil
    end
    #****************  CACHE DIALOG END  ************


    #****************  ACL  *************************
    def InitACLGroupsTable(key)
      items = []
      i = 0
      sup_acls = SquidACL.SupportedACLs

      Builtins.foreach(Squid.GetACLs) do |value|
        # test, if know how to handle this ACL
        if Builtins.contains(sup_acls, Ops.get_string(value, "type", ""))
          items = Builtins.add(
            items,
            Item(
              Id(i),
              Ops.get_string(value, "name", ""),
              Ops.get_string(value, "type", ""),
              Builtins.mergestring(Ops.get_list(value, "options", []), " ")
            )
          )
          i = Ops.add(i, 1)
        end
      end

      UI.ChangeWidget(Id("acl"), :Items, items)
      if Ops.greater_than(Builtins.size(items), 0)
        UI.ChangeWidget(Id(:edit_acl), :Enabled, true)
        UI.ChangeWidget(Id(:del_acl), :Enabled, true)
      else
        UI.ChangeWidget(Id(:edit_acl), :Enabled, false)
        UI.ChangeWidget(Id(:del_acl), :Enabled, false)
      end

      nil
    end


    def InitAddEditACLDialog(id_item)
      if id_item != nil
        acl = Squid.GetACL(id_item)
        UI.ChangeWidget(Id("name"), :Value, Ops.get_string(acl, "name", ""))
        UI.ChangeWidget(Id("type"), :Value, Ops.get_string(acl, "type", ""))
      end

      nil
    end
    #****************  ACL END  *********************


    #****************  HTTP_ACCESS  *****************
    def InitHttpAccessTable(key)
      items = []
      i = 0

      Builtins.foreach(Squid.GetHttpAccesses) do |value|
        items = Builtins.add(
          items,
          Item(
            Id(i),
            Ops.get_boolean(value, "allow", true) ? "allow" : "deny",
            Builtins.mergestring(Ops.get_list(value, "acl", []), " ")
          )
        )
        i = Ops.add(i, 1)
      end

      UI.ChangeWidget(Id("http_access"), :Items, items)
      if Ops.greater_than(Builtins.size(items), 0)
        UI.ChangeWidget(Id(:edit_http_access), :Enabled, true)
        UI.ChangeWidget(Id(:del_http_access), :Enabled, true)
        UI.ChangeWidget(Id(:up_http_access), :Enabled, true)
        UI.ChangeWidget(Id(:down_http_access), :Enabled, true)
      else
        UI.ChangeWidget(Id(:edit_http_access), :Enabled, false)
        UI.ChangeWidget(Id(:del_http_access), :Enabled, false)
        UI.ChangeWidget(Id(:up_http_access), :Enabled, false)
        UI.ChangeWidget(Id(:down_http_access), :Enabled, false)
      end

      nil
    end


    def InitAddEditHttpAccessDialog(id_item)
      items = []
      acls_items = []

      if id_item != nil
        http_access = Squid.GetHttpAccess(id_item)
        i = 0

        Builtins.foreach(Ops.get_list(http_access, "acl", [])) do |value|
          items = Builtins.add(
            items,
            Item(
              Id(i),
              Builtins.search(value, "!") == 0 ? "not" : "",
              Builtins.deletechars(value, "!")
            )
          )
          i = Ops.add(i, 1)
        end
        UI.ChangeWidget(Id("acls"), :Items, items)
        UI.ChangeWidget(
          Id("allow_deny"),
          :Value,
          Ops.get_boolean(http_access, "allow", true) ? "allow" : "deny"
        )

        items = []
      end

      Builtins.foreach(
        Convert.convert(
          UI.QueryWidget(Id("acls"), :Items),
          :from => "any",
          :to   => "list <term>"
        )
      ) do |value|
        acls_items = Builtins.add(acls_items, Ops.get_string(value, 2, ""))
      end

      Builtins.foreach(Squid.GetACLs) do |value|
        if !Builtins.contains(
            items,
            Item(
              Id(Ops.get_string(value, "name", "")),
              Ops.get_string(value, "name", "")
            )
          ) &&
            !Builtins.contains(acls_items, Ops.get_string(value, "name", ""))
          items = Builtins.add(
            items,
            Item(
              Id(Ops.get_string(value, "name", "")),
              Ops.get_string(value, "name", "")
            )
          )
        end
      end
      UI.ChangeWidget(Id("acl"), :Items, items)
      UI.ChangeWidget(Id("acl_not"), :Value, false)

      nil
    end
    #****************  HTTP_ACCESS END  *************




    #*********  LOGGING AND TIMETOUS DIALOG  ********
    def InitLoggingFrame(key)
      set = Convert.convert(
        Squid.GetSettings,
        :from => "map <string, any>",
        :to   => "map <string, list>"
      )
      simpleInit(
        {
          "access_log"        => Ops.get_string(
            Ops.get(set, "access_log", []),
            0,
            ""
          ),
          "cache_log"         => Ops.get_string(
            Ops.get(set, "cache_log", []),
            0,
            ""
          ),
          "cache_store_log"   => Ops.get_string(
            Ops.get(set, "cache_store_log", []),
            0,
            ""
          )
        }
      )

      nil
    end

    def InitTimeoutsFrame(key)
      set = Convert.convert(
        Squid.GetSettings,
        :from => "map <string, any>",
        :to   => "map <string, list>"
      )
      simpleInit(
        {
          "connect_timeout"       => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "connect_timeout", []), 0, "")
          ),
          "connect_timeout_units" => Ops.get_string(
            Ops.get(set, "connect_timeout", []),
            1,
            ""
          ),
          "client_lifetime"       => Builtins.tointeger(
            Ops.get_string(Ops.get(set, "client_lifetime", []), 0, "")
          ),
          "client_lifetime_units" => Ops.get_string(
            Ops.get(set, "client_lifetime", []),
            1,
            ""
          )
        }
      )

      nil
    end
    #*********  LOGGING AND TIMETOUS DIALOG END  ****


    def InitMiscellaneousFrame(key)
      simpleInit(
        {
          "cache_mgr"   => Ops.get(Squid.GetSetting("cache_mgr"), 0, ""),
          "ftp_passive" => Ops.get(Squid.GetSetting("ftp_passive"), 0, "") == "on" ? true : false
        }
      )
      UI.ChangeWidget(
        Id("error_language"),
        :Items,
        SquidErrorMessages.GetLanguagesToComboBox
      )
      UI.ChangeWidget(
        Id("error_language"),
        :Value,
        SquidErrorMessages.GetLanguageFromPath(
          Ops.get(Squid.GetSetting("error_directory"), 0, "")
        )
      )

      nil
    end
  end
end
