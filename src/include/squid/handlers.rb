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

# File:	include/squid/handlers.ycp
# Package:	Configuration of squid
# Summary:	Handle functions to CWM
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: wizards.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module SquidHandlersInclude
    def initialize_squid_handlers(include_target)
      Yast.import "UI"

      textdomain "squid"

      Yast.include include_target, "squid/inits.rb"
      Yast.include include_target, "squid/store_del.rb"
      Yast.include include_target, "squid/dialogs.rb"
      Yast.include include_target, "squid/popup_dialogs.rb"
    end

    def HandleHttpPortsTable(widget_id, event_map)
      event_map = deep_copy(event_map)
      ui = Ops.get(event_map, "ID")
      id_item = nil

      Builtins.y2debug(
        "HandleHttpPortsTable: widget_id: %1, event_map: %2",
        widget_id,
        event_map
      )

      if ui == :add
        InitHttpPortsTable("") if AddEditHttpPortDialog(nil)
      elsif ui == :edit || ui == "http_port"
        id_item = Convert.to_integer(
          UI.QueryWidget(Id("http_port"), :CurrentItem)
        )
        if AddEditHttpPortDialog(id_item)
          InitHttpPortsTable("")
          UI.ChangeWidget(Id("http_port"), :CurrentItem, id_item)
        end
      elsif ui == :del
        id_item = DelFromHttpPortsTable(
          Convert.to_integer(UI.QueryWidget(Id("http_port"), :CurrentItem))
        )
        InitHttpPortsTable("")
        UI.ChangeWidget(Id("http_port"), :CurrentItem, id_item)
      end
      nil
    end


    def HandleRefreshPatternsTable(widget_id, event_map)
      event_map = deep_copy(event_map)
      ui = Ops.get(event_map, "ID")
      id_item = nil

      if ui == :add
        InitRefreshPatternsTable("") if AddEditRefreshPatternDialog(nil)
      elsif ui == :edit || ui == "refresh_patterns"
        id_item = Convert.to_integer(
          UI.QueryWidget(Id("refresh_patterns"), :CurrentItem)
        )
        if AddEditRefreshPatternDialog(id_item)
          InitRefreshPatternsTable("")
          UI.ChangeWidget(Id("refresh_patterns"), :CurrentItem, id_item)
        end
      elsif ui == :del
        id_item = DelFromRefreshPatternsTable(
          Convert.to_integer(
            UI.QueryWidget(Id("refresh_patterns"), :CurrentItem)
          )
        )
        InitRefreshPatternsTable("")
        UI.ChangeWidget(Id("refresh_patterns"), :CurrentItem, id_item)
      elsif ui == :up
        id_item = MoveUpRefreshPattern(
          Convert.to_integer(
            UI.QueryWidget(Id("refresh_patterns"), :CurrentItem)
          )
        )
        if id_item != nil
          InitRefreshPatternsTable("")
          UI.ChangeWidget(Id("refresh_patterns"), :CurrentItem, id_item)
        end
      elsif ui == :down
        id_item = MoveDownRefreshPattern(
          Convert.to_integer(
            UI.QueryWidget(Id("refresh_patterns"), :CurrentItem)
          )
        )
        if id_item != nil
          InitRefreshPatternsTable("")
          UI.ChangeWidget(Id("refresh_patterns"), :CurrentItem, id_item)
        end
      end
      nil
    end


    def HandleCache2Dialog(widget_id, event_map)
      event_map = deep_copy(event_map)
      ui = Ops.get(event_map, "ID")
      tmp = nil
      tmp2 = nil

      #cache_min_object_size <= cache_max_object_size
      if ui == "cache_min_object_size" || ui == "cache_min_object_size_units"
        tmp = Ops.multiply(
          Convert.to_integer(
            UI.QueryWidget(Id("cache_min_object_size"), :Value)
          ),
          unitToMultiple(
            Convert.to_string(
              UI.QueryWidget(Id("cache_min_object_size_units"), :Value)
            )
          )
        )
        tmp2 = Ops.multiply(
          Convert.to_integer(
            UI.QueryWidget(Id("cache_max_object_size"), :Value)
          ),
          unitToMultiple(
            Convert.to_string(
              UI.QueryWidget(Id("cache_max_object_size_units"), :Value)
            )
          )
        )
        if Ops.greater_than(Convert.to_integer(tmp), Convert.to_integer(tmp2))
          UI.ChangeWidget(
            Id("cache_max_object_size"),
            :Value,
            UI.QueryWidget(Id("cache_min_object_size"), :Value)
          )
          UI.ChangeWidget(
            Id("cache_max_object_size_units"),
            :Value,
            UI.QueryWidget(Id("cache_min_object_size_units"), :Value)
          )
        end
      elsif ui == "cache_max_object_size" || ui == "cache_max_object_size_units"
        tmp = Ops.multiply(
          Convert.to_integer(
            UI.QueryWidget(Id("cache_min_object_size"), :Value)
          ),
          unitToMultiple(
            Convert.to_string(
              UI.QueryWidget(Id("cache_min_object_size_units"), :Value)
            )
          )
        )
        tmp2 = Ops.multiply(
          Convert.to_integer(
            UI.QueryWidget(Id("cache_max_object_size"), :Value)
          ),
          unitToMultiple(
            Convert.to_string(
              UI.QueryWidget(Id("cache_max_object_size_units"), :Value)
            )
          )
        )
        if Ops.greater_than(Convert.to_integer(tmp), Convert.to_integer(tmp2))
          UI.ChangeWidget(
            Id("cache_min_object_size"),
            :Value,
            UI.QueryWidget(Id("cache_max_object_size"), :Value)
          )
          UI.ChangeWidget(
            Id("cache_min_object_size_units"),
            :Value,
            UI.QueryWidget(Id("cache_max_object_size_units"), :Value)
          )
        end 

        #cache_swap_low <= cache_swap_high
      elsif ui == "cache_swap_low"
        tmp = UI.QueryWidget(Id("cache_swap_low"), :Value)
        if Ops.greater_than(
            Convert.to_integer(tmp),
            Convert.to_integer(UI.QueryWidget(Id("cache_swap_high"), :Value))
          )
          UI.ChangeWidget(Id("cache_swap_high"), :Value, tmp)
        end
      elsif ui == "cache_swap_high"
        tmp = UI.QueryWidget(Id("cache_swap_high"), :Value)
        if Ops.greater_than(
            Convert.to_integer(UI.QueryWidget(Id("cache_swap_low"), :Value)),
            Convert.to_integer(tmp)
          )
          UI.ChangeWidget(Id("cache_swap_low"), :Value, tmp)
        end
      end
      nil
    end

    def HandleCacheDirectoryDialog(widget_id, event_map)
      event_map = deep_copy(event_map)
      ui = Ops.get(event_map, "ID")
      cache_dir = ""

      if ui == :browse_cache_dir
        cache_dir = UI.AskForExistingDirectory(
          Convert.to_string(UI.QueryWidget(Id("cache_dir"), :Value)),
          _("Cache Directory")
        )
        UI.ChangeWidget(Id("cache_dir"), :Value, cache_dir) if cache_dir != nil
      end

      nil
    end

    def HandleAccessControlDialog(widget_id, event_map)
      event_map = deep_copy(event_map)
      ui = Ops.get(event_map, "ID")
      id_item = nil

      if ui == :add_acl
        InitACLGroupsTable("") if AddEditACLDialog(nil)
      elsif ui == :edit_acl || ui == "acl"
        id_item = Convert.to_integer(UI.QueryWidget(Id("acl"), :CurrentItem))
        if AddEditACLDialog(id_item)
          InitACLGroupsTable("")
          UI.ChangeWidget(Id("acl"), :CurrentItem, id_item)
        end
      elsif ui == :del_acl
        id_item = DelFromACLGroupsTable(
          Convert.to_integer(UI.QueryWidget(Id("acl"), :CurrentItem))
        )
        InitACLGroupsTable("")
        UI.ChangeWidget(Id("acl"), :CurrentItem, id_item)
      elsif ui == :add_http_access
        InitHttpAccessTable("") if AddEditHttpAccessDialog(nil)
      elsif ui == :edit_http_access || ui == "http_access"
        id_item = Convert.to_integer(
          UI.QueryWidget(Id("http_access"), :CurrentItem)
        )
        if AddEditHttpAccessDialog(id_item)
          InitHttpAccessTable("")
          UI.ChangeWidget(Id("http_access"), :CurrentItem, id_item)
        end
      elsif ui == :del_http_access
        id_item = DelFromHttpAccessTable(
          Convert.to_integer(UI.QueryWidget(Id("http_access"), :CurrentItem))
        )
        InitHttpAccessTable("")
        UI.ChangeWidget(Id("http_access"), :CurrentItem, id_item)
      elsif ui == :up_http_access
        id_item = MoveUpHttpAccess(
          Convert.to_integer(UI.QueryWidget(Id("http_access"), :CurrentItem))
        )
        if id_item != nil
          InitHttpAccessTable("")
          UI.ChangeWidget(Id("http_access"), :CurrentItem, id_item)
        end
      elsif ui == :down_http_access
        id_item = MoveDownHttpAccess(
          Convert.to_integer(UI.QueryWidget(Id("http_access"), :CurrentItem))
        )
        if id_item != nil
          InitHttpAccessTable("")
          UI.ChangeWidget(Id("http_access"), :CurrentItem, id_item)
        end
      end
      nil
    end


    def HandleLoggingFrame(widget_id, event_map)
      event_map = deep_copy(event_map)
      ui = Ops.get(event_map, "ID")
      tmp = nil

      if ui == :access_log_browse
        tmp = UI.AskForExistingFile("/var/log", "*", _("Access Log"))
        UI.ChangeWidget(Id("access_log"), :Value, tmp) if tmp != nil
      elsif ui == :cache_log_browse
        tmp = UI.AskForExistingFile("/var/log", "*", _("Cache Log"))
        UI.ChangeWidget(Id("cache_log"), :Value, tmp) if tmp != nil
      elsif ui == :cache_store_log_browse
        tmp = UI.AskForExistingFile("/var/log", "*", _("Cache Store Log"))
        UI.ChangeWidget(Id("cache_store_log"), :Value, tmp) if tmp != nil
      end
      nil
    end
  end
end
