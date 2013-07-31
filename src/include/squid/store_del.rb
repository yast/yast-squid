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

# File:	include/squid/store_del.ycp
# Package:	Configuration of squid
# Summary:	All Store.. Del.. Move.. functions for dialogs.
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id$
module Yast
  module SquidStoreDelInclude
    def initialize_squid_store_del(include_target)
      Yast.import "UI"

      textdomain "squid"

      Yast.import "Label"
      Yast.import "Report"
      Yast.import "FileUtils"
      Yast.import "Popup"
      Yast.import "Mode"

      Yast.import "Squid"
      Yast.import "SquidACL"
      Yast.import "SquidErrorMessages"

      Yast.include include_target, "squid/helper_functions.rb"
    end

    #****************  HTTP_PORT  *******************
    def StoreDataFromAddEditHttpPortDialog(id_item)
      ok = true
      host = Convert.to_string(UI.QueryWidget(Id("host"), :Value))
      port = Convert.to_string(UI.QueryWidget(Id("port"), :Value))
      transparent = Convert.to_boolean(
        UI.QueryWidget(Id("transparent"), :Value)
      )
      error_msg = ""

      if Builtins.size(port) == 0
        error_msg = Ops.add(
          Ops.add(
            error_msg,
            Ops.greater_than(Builtins.size(error_msg), 0) ? "\n" : ""
          ),
          _("Port number must not be empty.")
        )
        ok = false
      end
      if Ops.greater_than(Builtins.size(host), 0) && !isCorrectHost(host)
        error_msg = Ops.add(
          Ops.add(
            error_msg,
            Ops.greater_than(Builtins.size(error_msg), 0) ? "\n" : ""
          ),
          _("Host must contain valid IP address or hostname.")
        )
        ok = false
      end


      if ok
        if id_item == nil
          Squid.AddHttpPort(host, port, transparent)
        else
          Squid.ModifyHttpPort(id_item, host, port, transparent)
        end
      else
        Report.Error(error_msg)
      end

      ok
    end

    def DelFromHttpPortsTable(id_item)
      Squid.DelHttpPort(id_item)
      if Ops.greater_or_equal(id_item, Builtins.size(Squid.GetHttpPorts))
        id_item = Ops.subtract(id_item, 1)
      end
      id_item
    end
    #****************  HTTP_PORT END  ***************



    #*************  REFRESH_PATTERNS  ***************
    def StoreDataFromAddEditRefreshPatternDialog(id_item)
      ok = true
      regexp = Convert.to_string(UI.QueryWidget(Id("regexp"), :Value))
      min = Builtins.tostring(UI.QueryWidget(Id("min"), :Value))
      percent = Builtins.tostring(UI.QueryWidget(Id("percent"), :Value))
      max = Builtins.tostring(UI.QueryWidget(Id("max"), :Value))
      case_sensitive = !Convert.to_boolean(
        UI.QueryWidget(Id("regexp_case_insensitive"), :Value)
      )

      if Ops.greater_than(Builtins.size(regexp), 0)
        if id_item == nil
          Squid.AddRefreshPattern(regexp, min, percent, max, case_sensitive)
        else
          Squid.ModifyRefreshPattern(
            id_item,
            regexp,
            min,
            percent,
            max,
            case_sensitive
          )
        end
      else
        Report.Error(_("Regular expression must not be empty."))
        ok = false
      end

      ok
    end

    def DelFromRefreshPatternsTable(id_item)
      Squid.DelRefreshPattern(id_item)
      if Ops.greater_or_equal(id_item, Builtins.size(Squid.GetRefreshPatterns))
        id_item = Ops.subtract(id_item, 1)
      end
      id_item
    end

    # returns new position or nil if not moved
    def MoveUpRefreshPattern(id_item)
      ret = nil

      if Ops.greater_than(id_item, 0)
        Squid.MoveRefreshPattern(id_item, Ops.subtract(id_item, 1))
        ret = Ops.subtract(id_item, 1)
      end
      ret
    end
    # returns new position or nil if not moved
    def MoveDownRefreshPattern(id_item)
      ret = nil

      if Ops.less_than(
          id_item,
          Ops.subtract(Builtins.size(Squid.GetRefreshPatterns), 1)
        )
        Squid.MoveRefreshPattern(id_item, Ops.add(id_item, 1))
        ret = Ops.add(id_item, 1)
      end
      ret
    end
    #*************  REFRESH_PATTERNS END  ***********



    #*************  CACHE DIALOG  *******************
    def ValidateCache2Dialog(widget_id, event)
      event = deep_copy(event)
      ok = true

      if Ops.get(event, "ID") != :abort
        cache_mem = Ops.multiply(
          Convert.to_integer(UI.QueryWidget(Id("cache_mem"), :Value)),
          unitToMultiple(
            Convert.to_string(UI.QueryWidget(Id("cache_mem_units"), :Value))
          )
        )
        cache_dir_str = Squid.GetSetting("cache_dir")
        cache_dir_mbytes = Ops.multiply(
          Ops.multiply(Builtins.tointeger(Ops.get(cache_dir_str, 2, "0")), 1024),
          1024
        )
        max_obj_size = Ops.multiply(
          Convert.to_integer(
            UI.QueryWidget(Id("cache_max_object_size"), :Value)
          ),
          unitToMultiple(
            Convert.to_string(
              UI.QueryWidget(Id("cache_max_object_size_units"), :Value)
            )
          )
        )

        if Ops.greater_than(max_obj_size, Ops.add(cache_mem, cache_dir_mbytes))
          ok = false
          Report.Error(
            _(
              "Cache Memory + Size of Cache Directory\nmust be higher than Max Object Size.\n"
            )
          )
        end
      end

      ok
    end
    def StoreDataFromCache2Dialog(widget_id, event)
      event = deep_copy(event)
      Squid.SetSetting(
        "cache_mem",
        [
          Builtins.tostring(UI.QueryWidget(Id("cache_mem"), :Value)),
          UI.QueryWidget(Id("cache_mem_units"), :Value)
        ]
      )
      Squid.SetSetting(
        "maximum_object_size",
        [
          Builtins.tostring(UI.QueryWidget(Id("cache_max_object_size"), :Value)),
          UI.QueryWidget(Id("cache_max_object_size_units"), :Value)
        ]
      )
      Squid.SetSetting(
        "minimum_object_size",
        [
          Builtins.tostring(UI.QueryWidget(Id("cache_min_object_size"), :Value)),
          UI.QueryWidget(Id("cache_min_object_size_units"), :Value)
        ]
      )
      Squid.SetSetting(
        "cache_swap_low",
        [Builtins.tostring(UI.QueryWidget(Id("cache_swap_low"), :Value))]
      )
      Squid.SetSetting(
        "cache_swap_high",
        [Builtins.tostring(UI.QueryWidget(Id("cache_swap_high"), :Value))]
      )
      Squid.SetSetting(
        "cache_replacement_policy",
        [UI.QueryWidget(Id("cache_replacement_policy"), :Value)]
      )
      Squid.SetSetting(
        "memory_replacement_policy",
        [UI.QueryWidget(Id("memory_replacement_policy"), :Value)]
      )

      nil
    end


    def ValidateCacheDirectoryDialog(widget_id, event)
      event = deep_copy(event)
      ok = true

      if Ops.get(event, "ID") != :abort
        cache_dir = Convert.to_string(UI.QueryWidget(Id("cache_dir"), :Value))

        if Builtins.size(cache_dir) == 0
          ok = false
          Report.Error(_("Cache directory must not be empty."))
        elsif Mode.normal && !FileUtils.CheckAndCreatePath(cache_dir)
          ok = false
        else
          cache_mem_str = Squid.GetSetting("cache_mem")
          cache_mem = Ops.multiply(
            Builtins.tointeger(Ops.get(cache_mem_str, 0, "0")),
            unitToMultiple(Ops.get(cache_mem_str, 1, "KB"))
          )
          cache_dir_mbytes = Ops.multiply(
            Ops.multiply(
              Convert.to_integer(UI.QueryWidget(Id("mbytes"), :Value)),
              1024
            ),
            1024
          )
          max_obj_size_str = Squid.GetSetting("maximum_object_size")
          max_obj_size = Ops.multiply(
            Builtins.tointeger(Ops.get(max_obj_size_str, 0, "0")),
            unitToMultiple(Ops.get(max_obj_size_str, 1, "KB"))
          )

          if Ops.greater_than(
              max_obj_size,
              Ops.add(cache_mem, cache_dir_mbytes)
            )
            ok = false
            Report.Error(
              _(
                "Cache Memory + Size of Cache Directory\nmust be higher than Max Object Size.\n"
              )
            )
          end
        end
      end

      ok
    end
    def StoreDataFromCacheDirectoryDialog(widget_id, event)
      event = deep_copy(event)
      squid_cache_dir = Squid.GetSetting("cache_dir")

      Squid.SetSetting(
        "cache_dir",
        [
          Ops.get_string(squid_cache_dir, 0, ""),
          Convert.to_string(UI.QueryWidget(Id("cache_dir"), :Value)),
          Builtins.tostring(UI.QueryWidget(Id("mbytes"), :Value)),
          Builtins.tostring(UI.QueryWidget(Id("l1dirs"), :Value)),
          Builtins.tostring(UI.QueryWidget(Id("l2dirs"), :Value))
        ]
      )

      nil
    end
    #*************  CACHE DIALOG END  ***************



    #*************  HTTP_ACCESS  ********************
    def StoreDataFromAddEditHttpAccessDialog(id_item)
      ok = true
      allow = true
      acls = []
      tmp = ""

      allow = UI.QueryWidget(Id("allow_deny"), :Value) == "allow" ? true : false
      Builtins.foreach(
        Convert.convert(
          UI.QueryWidget(Id("acls"), :Items),
          :from => "any",
          :to   => "list <term>"
        )
      ) do |value|
        tmp = Ops.get_string(value, 1, "") == "not" ? "!" : ""
        tmp = Ops.add(tmp, Ops.get_string(value, 2, ""))
        acls = Builtins.add(acls, tmp)
      end

      if Ops.greater_than(Builtins.size(acls), 0)
        if id_item == nil
          Squid.AddHttpAccess(allow, acls)
        else
          Squid.ModifyHttpAccess(id_item, allow, acls)
        end
      else
        ok = false
        Report.Error(_("ACL table must not be empty."))
      end

      ok
    end
    def DelFromHttpAccessTable(id_item)
      Squid.DelHttpAccess(id_item)
      if Ops.greater_or_equal(id_item, Builtins.size(Squid.GetHttpAccesses))
        id_item = Ops.subtract(id_item, 1)
      end
      id_item
    end
    def MoveUpHttpAccess(id_item)
      ret = nil

      if Ops.greater_than(id_item, 0)
        Squid.MoveHttpAccess(id_item, Ops.subtract(id_item, 1))
        ret = Ops.subtract(id_item, 1)
      end
      ret
    end
    def MoveDownHttpAccess(id_item)
      ret = nil

      if Ops.less_than(
          id_item,
          Ops.subtract(Builtins.size(Squid.GetHttpAccesses), 1)
        )
        Squid.MoveHttpAccess(id_item, Ops.add(id_item, 1))
        ret = Ops.add(id_item, 1)
      end
      ret
    end
    #*************  HTTP_ACCESS END  ****************



    #*************  ACL  ****************************
    def StoreDataFromAddEditACLDialog(id_item)
      ok = true

      type = Convert.to_string(UI.QueryWidget(Id("type"), :Value))
      name = Convert.to_string(UI.QueryWidget(Id("name"), :Value))
      options = SquidACL.GetOptions(type)

      verification = SquidACL.Verify(type)

      affected_options = []
      num_acls = nil
      old_name = nil
      if id_item != nil
        affected_options = Squid.ACLIsUsedBy(id_item)
        num_acls = Squid.NumACLs(id_item)
        old_name = Ops.get_string(Squid.GetACL(id_item), "name", "")
      end

      if verification && Ops.greater_than(Builtins.size(name), 0)
        # test, if exists ACL with same name but different type
        existed_type = Squid.GetACLTypeByName(name)
        if existed_type != nil && existed_type != type
          error = false

          if id_item != nil
            numACLs = Squid.NumACLsByName(name)
            if name != old_name && Ops.greater_than(numACLs, 0) ||
                name == old_name && Ops.greater_than(numACLs, 1)
              error = true
            end
          else
            error = true
          end

          if error
            ok = false
            Report.Error(
              Ops.add(
                Ops.add(
                  Builtins.sformat(
                    _("ACL Group '%1' already exists with different type.\n"),
                    name
                  ),
                  Builtins.sformat(
                    _("ACL Group '%1' must have type '%2'.\n"),
                    name,
                    existed_type
                  )
                ),
                _(
                  "If you want to change the type of this ACL Group, you must\ndelete other ACL Groups with the same name before that.\n"
                )
              )
            )
          end
        end

        #verification where name is changed and this ACL has 1 occurrence
        if ok && id_item != nil && old_name != name &&
            Squid.NumACLs(id_item) == 1
          #test if changed ACL is used in http_access option.
          if Ops.greater_than(Builtins.size(affected_options), 0) &&
              Builtins.contains(affected_options, "http_access")
            Report.Error(
              _(
                "You can not change the name of this ACL Group, because \nit is used in the Access Control table.\n"
              ) +
                _(
                  "If you want to change name of this ACL Group you must\ndelete all of its occurrences in Access Control table."
                )
            )
            ok = false
          #test if changed ACL is used in other option (not managed by thid module)
          elsif Ops.greater_than(Builtins.size(affected_options), 0)
            if !Report.AnyQuestion(
                Label.WarningMsg,
                Ops.add(
                  Ops.add(
                    _(
                      "If you change the name of this ACL Group, these options might be affected: \n"
                    ) + "    ",
                    Builtins.mergestring(affected_options, ",\n    ")
                  ),
                  ".\n"
                ),
                _("Change name anyway"),
                _("Do not change name"),
                :focus_no
              )
              ok = false
            end
          end
        end
      elsif verification
        #test, if name is filled
        ok = false
        Report.Error(_("Name must not be empty."))
      else
        ok = false
      end

      if ok && id_item == nil
        Squid.AddACL(name, type, options)
      elsif ok
        Squid.ModifyACL(id_item, name, type, options)
      end
      ok
    end

    # Delete ACL with id id_item.
    # If ACL has only one occurrence (one definition line) in config file and
    # ACL is used by any option (http_access, no_cache ...) than user is asked
    # if he really want to delete the ACL. If option 'http_access' uses this ACL
    # than it's unaccepted to delete the ACL.
    def DelFromACLGroupsTable(id_item)
      ok = true

      if Squid.NumACLs(id_item) == 1
        affected_options = Squid.ACLIsUsedBy(id_item)
        if Ops.greater_than(Builtins.size(affected_options), 0)
          ok = false

          if Builtins.contains(affected_options, "http_access")
            #Report::Error( _("This ACL Group can't be deleted.\nIt's used in Access Control table."));
            Report.Error(
              _(
                "You must not delete this ACL Group, because \nit is used in the Access Control table.\n"
              ) +
                _(
                  "If you want to change name of this ACL Group you must\ndelete all of its occurrences in Access Control table."
                )
            )
          else
            message = Ops.add(
              Ops.add(
                _(
                  "If you delete this ACL Group, these options might be affected: \n"
                ) + "    ",
                Builtins.mergestring(affected_options, ",\n    ")
              ),
              ".\n"
            ) # +
            #_("Are you sure you want to delete this ACL Group?");
            if Report.AnyQuestion(
                Label.WarningMsg,
                message,
                _("Delete anyway"), #Label::YesButton(),
                _("Do not delete"), #Label::NoButton(),
                :focus_no
              )
              ok = true
            end
          end
        end
      end

      if ok
        Squid.DelACL(id_item)
        if Ops.greater_or_equal(id_item, Builtins.size(Squid.GetACLs))
          id_item = Ops.subtract(id_item, 1)
        end
      end

      id_item
    end
    #*************  ACL END  ************************




    #*******  LOGGING AND TIMEOUTS DIALOG  **********
    def ValidateLoggingFrame(widget_id, event)
      event = deep_copy(event)
      if Ops.get(event, "ID") != :abort
        ok = true
        message = ""
        access_log = Convert.to_string(UI.QueryWidget(Id("access_log"), :Value))
        cache_log = Convert.to_string(UI.QueryWidget(Id("cache_log"), :Value))
        cache_store_log = Convert.to_string(
          UI.QueryWidget(Id("cache_store_log"), :Value)
        )
        emulate_httpd_log = Convert.to_boolean(
          UI.QueryWidget(Id("emulate_httpd_log"), :Value)
        ) ? "on" : "off"

        if Builtins.size(access_log) == 0
          ok = false
          message = Ops.add(
            Ops.add(
              message,
              Ops.greater_than(Builtins.size(message), 0) ? "\n" : ""
            ),
            _("Access Log must not be empty.")
          )
        end
        if Builtins.size(cache_log) == 0
          ok = false
          message = Ops.add(
            Ops.add(
              message,
              Ops.greater_than(Builtins.size(message), 0) ? "\n" : ""
            ),
            _("Cache Log must not be empty.")
          )
        end
        if Ops.greater_than(Builtins.size(access_log), 0) && Mode.normal &&
            !isCorrectPathnameOfLogFile(access_log)
          ok = false
          message = Ops.add(
            Ops.add(
              message,
              Ops.greater_than(Builtins.size(message), 0) ? "\n" : ""
            ),
            _("Incorrect pathname in Access Log field.")
          )
        end
        if Ops.greater_than(Builtins.size(cache_log), 0) && Mode.normal &&
            !isCorrectPathnameOfLogFile(cache_log)
          ok = false
          message = Ops.add(
            Ops.add(
              message,
              Ops.greater_than(Builtins.size(message), 0) ? "\n" : ""
            ),
            _("Incorrect pathname in Cache Log field.")
          )
        end
        if Ops.greater_than(Builtins.size(cache_store_log), 0) && Mode.normal &&
            !isCorrectPathnameOfLogFile(cache_store_log)
          ok = false
          message = Ops.add(
            Ops.add(
              message,
              Ops.greater_than(Builtins.size(message), 0) ? "\n" : ""
            ),
            _("Incorrect pathname in Cache Store Log field.")
          )
        end
        # if (size(cache_store_log) == 0){
        #    ok = false;
        #    message = message + (size(message)>0 ? "\n" : "") + _("Cache Store Log must not be empty.");
        # }

        Report.Error(message) if !ok

        return ok
      end
      true
    end
    def StoreDataFromLoggingFrame(widget_id, event)
      event = deep_copy(event)
      access_log = Convert.to_string(UI.QueryWidget(Id("access_log"), :Value))
      cache_log = Convert.to_string(UI.QueryWidget(Id("cache_log"), :Value))
      cache_store_log = Convert.to_string(
        UI.QueryWidget(Id("cache_store_log"), :Value)
      )
      emulate_httpd_log = Convert.to_boolean(
        UI.QueryWidget(Id("emulate_httpd_log"), :Value)
      ) ? "on" : "off"

      tmp = Squid.GetSetting("access_log")
      Squid.SetSetting(
        "access_log",
        Builtins.prepend(Builtins.remove(tmp, 0), access_log)
      )
      Squid.SetSetting("cache_log", [cache_log])
      Squid.SetSetting("cache_store_log", [cache_store_log])
      Squid.SetSetting("emulate_httpd_log", [emulate_httpd_log])

      nil
    end

    def StoreDataFromTimeoutsFrame(widget_id, event)
      event = deep_copy(event)
      Squid.SetSetting(
        "connect_timeout",
        [
          Builtins.tostring(UI.QueryWidget(Id("connect_timeout"), :Value)),
          Convert.to_string(UI.QueryWidget(Id("connect_timeout_units"), :Value))
        ]
      )
      Squid.SetSetting(
        "client_lifetime",
        [
          Builtins.tostring(UI.QueryWidget(Id("client_lifetime"), :Value)),
          Convert.to_string(UI.QueryWidget(Id("client_lifetime_units"), :Value))
        ]
      )

      nil
    end
    #*******  LOGGING AND TIMEOUTS DIALOG END  ******

    def ValidateMiscellaneousFrame(widget_id, event)
      event = deep_copy(event)
      if Ops.get(event, "ID") != :abort
        ok = true
        cache_mgr = Convert.to_string(UI.QueryWidget(Id("cache_mgr"), :Value))

        if Builtins.regexpmatch(cache_mgr, "[ \t\n]")
          ok = false
          Report.Error(
            _("Administrator's email must not contain any white spaces.")
          )
        end

        return ok
      end
      true
    end
    def StoreDataFromMiscellaneousFrame(widget_id, event)
      event = deep_copy(event)
      error_language = Convert.to_string(
        UI.QueryWidget(Id("error_language"), :Value)
      )
      cache_mgr = Convert.to_string(UI.QueryWidget(Id("cache_mgr"), :Value))
      ftp_passive = Convert.to_boolean(
        UI.QueryWidget(Id("ftp_passive"), :Value)
      ) ? "on" : "off"

      Squid.SetSetting(
        "error_directory",
        [SquidErrorMessages.GetPath(error_language)]
      )
      Squid.SetSetting("cache_mgr", [cache_mgr])
      Squid.SetSetting("ftp_passive", [ftp_passive])

      nil
    end
  end
end
