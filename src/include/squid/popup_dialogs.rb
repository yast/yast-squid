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

# File:	include/squid/popup_dialogs.ycp
# Package:	Configuration of squid
# Summary:	Popup dialogs definitions
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id$
module Yast
  module SquidPopupDialogsInclude
    def initialize_squid_popup_dialogs(include_target)
      Yast.import "UI"

      textdomain "squid"
      Yast.import "Label"
      Yast.import "SquidACL"

      Yast.include include_target, "squid/inits.rb"
      Yast.include include_target, "squid/store_del.rb"
      Yast.include include_target, "squid/helper_functions.rb"
    end

    # ****************  HTTP PORT  *******************
    # returns true if something added/edited otherwise false
    def AddEditHttpPortDialog(id_item)
      ui = nil
      ret = false
      label = id_item.nil? ? _("Add New HTTP Port") : _("Edit Current HTTP Port")
      contents = VBox(
        Label(label),
        VSpacing(0.5),
        TextEntry(Id("host"), _("Host"), ""),
        TextEntry(Id("port"), _("Port"), ""),
        Left(CheckBox(Id("transparent"), _("Transparent"), false)),
        VSpacing(),
        VStretch(),
        ButtonBox(
          PushButton(Id(:ok), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )

      UI.OpenDialog(Opt(:decorated), contents)
      UI.ChangeWidget(Id("port"), :ValidChars, "1234567890")
      UI.ChangeWidget(Id("host"), :InputMaxLength, 22)

      InitAddEditHttpPortDialog(id_item)

      loop do
        ui = UI.UserInput

        if ui == :abort || ui == :cancel
          ret = false
          break
        elsif ui == :ok
          if StoreDataFromAddEditHttpPortDialog(id_item)
            ret = true
            break
          end
        end
      end

      UI.CloseDialog
      ret
    end
    # ****************  HTTP PORT END  ***************

    # ****************  CACHE  ***********************
    def AddEditRefreshPatternDialog(id_item)
      ret = false
      ui = nil
      label = id_item.nil? ? _("Add New Refresh Pattern") : _("Edit Current refresh Pattern")
      tmp = nil

      contents = VBox(
        Label(label),
        VSpacing(0.5),
        VSquash(
          HBox(
            TextEntry(Id("regexp"), _("Regular Expression"), ""),
            Bottom(
              CheckBox(Id("regexp_case_insensitive"), _("Case Insensitive"))
            )
          )
        ),
        IntField(Id("min"), Opt(:notify), _("Min (in minutes)"), 0, 99999, 0),
        IntField(Id("percent"), _("Percent"), 0, 99999, 0),
        IntField(Id("max"), Opt(:notify), _("Max (in minutes)"), 0, 99999, 0),
        VSpacing(),
        VStretch(),
        ButtonBox(
          PushButton(Id(:ok), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )

      UI.OpenDialog(Opt(:decorated), contents)

      InitAddEditRefreshPatternDialog(id_item)

      loop do
        ui = UI.UserInput

        if ui == :cancel || ui == :abort
          ret = false
          break
        elsif ui == :ok
          if StoreDataFromAddEditRefreshPatternDialog(id_item)
            ret = true
            break
          end
        elsif ui == "min"
          if Ops.greater_than(
            Convert.to_integer(tmp),
            Convert.to_integer(UI.QueryWidget(Id("max"), :Value))
          )
            UI.ChangeWidget(Id("max"), :Value, tmp)
          end
        elsif ui == "max"
          tmp = UI.QueryWidget(Id("max"), :Value)
          if Ops.greater_than(
            Convert.to_integer(UI.QueryWidget(Id("min"), :Value)),
            Convert.to_integer(tmp)
          )
            UI.ChangeWidget(Id("min"), :Value, tmp)
          end
        end
      end

      UI.CloseDialog
      ret
    end
    # ****************  CACHE END  *******************

    # ****************  ACCESS CONTROL  **************
    def addItemToAddEditHttpAccessDialog(acl_not, item)
      items = []

      i = 0
      Builtins.foreach(
        Convert.convert(
          UI.QueryWidget(Id("acls"), :Items),
          from: "any",
          to:   "list <term>"
        )
      ) do |value|
        items = Builtins.add(
          items,
          Item(
            Id(i),
            Ops.get_string(value, 1, ""),
            Ops.get_string(value, 2, "")
          )
        )
        i = Ops.add(i, 1)
      end
      items = Builtins.add(items, Item(Id(i), acl_not == true ? "not" : "", item))
      UI.ChangeWidget(Id("acls"), :Items, items)

      nil
    end

    def delItemFromAddEditHttpAccessDialog(id_item)
      items = []

      i = 0
      Builtins.foreach(
        Convert.convert(
          UI.QueryWidget(Id("acls"), :Items),
          from: "any",
          to:   "list <term>"
        )
      ) do |value|
        if Ops.get(value, 0) != Id(id_item)
          items = Builtins.add(
            items,
            Item(
              Id(i),
              Ops.get_string(value, 1, ""),
              Ops.get_string(value, 2, "")
            )
          )
          i = Ops.add(i, 1)
        end
      end
      UI.ChangeWidget(Id("acls"), :Items, items)
      if Ops.greater_or_equal(id_item, Builtins.size(items))
        id_item = Ops.subtract(id_item, 1)
      end
      id_item
    end

    def AddEditHttpAccessDialog(id_item)
      ret = false
      ui = nil
      acl = ""
      acl_not = false
      tmp_term = nil
      id_acl = 0
      label = id_item.nil? ? _("Add New HTTP Access") : _("Edit HTTP Access")
      contents = VBox(
        Label(label),
        VSpacing(0.5),
        ComboBox(
          Id("allow_deny"),
          _("Allow/Deny"),
          [Item(Id("allow"), _("Allow")), Item(Id("deny"), _("Deny"))]
        ),
        # `VSpacing(),
        MinSize(
          25,
          7,
          Table(Id("acls"), Opt(:notify), Header("   ", _("ACL")), [])
        ),
        Left(
          HBox(
            PushButton(Id(:del), Label.DeleteButton),
            PushButton(Id(:opposite), _("O&pposite"))
          )
        ),
        VSpacing(0.5),
        MinWidth(
          25,
          Frame(
            _("Add ACL"),
            VSquash(
              HBox(
                Bottom(CheckBox(Id("acl_not"), _("not"))),
                MinWidth(15, ComboBox(Id("acl"), "ACL", [])),
                Bottom(PushButton(Id(:add), Label.AddButton))
              )
            )
          )
        ),
        VStretch(),
        ButtonBox(
          PushButton(Id(:ok), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )

      UI.OpenDialog(contents)

      InitAddEditHttpAccessDialog(id_item)

      loop do
        ui = UI.UserInput

        if ui == :cancel || ui == :abort
          ret = false
          break
        elsif ui == :ok
          if StoreDataFromAddEditHttpAccessDialog(id_item)
            ret = true
            break
          end
        elsif ui == :add
          acl = Convert.to_string(UI.QueryWidget(Id("acl"), :Value))
          acl_not = Convert.to_boolean(UI.QueryWidget(Id("acl_not"), :Value))
          if Ops.greater_than(Builtins.size(acl), 0)
            addItemToAddEditHttpAccessDialog(acl_not, acl)
            InitAddEditHttpAccessDialog(nil)
          end
        elsif ui == :del
          id_acl = delItemFromAddEditHttpAccessDialog(
            Convert.to_integer(UI.QueryWidget(Id("acls"), :CurrentItem))
          )
          InitAddEditHttpAccessDialog(nil)
          UI.ChangeWidget(Id("acls"), :CurrentItem, id_acl)
        elsif ui == :opposite || ui == "acls"
          id_acl = Convert.to_integer(UI.QueryWidget(Id("acls"), :CurrentItem))
          tmp_term = Convert.to_term(
            UI.QueryWidget(Id("acls"), term(:Item, id_acl))
          )

          if Ops.get_string(tmp_term, 1, "") == "not"
            UI.ChangeWidget(Id("acls"), term(:Item, id_acl, 0), "")
          else
            UI.ChangeWidget(Id("acls"), term(:Item, id_acl, 0), "not")
          end
        end
      end

      UI.CloseDialog

      ret
    end

    def AddEditACLDialog(id_item)
      ret = false
      ui = nil
      orig_type = ""
      type = ""
      label = id_item.nil? ? _("Add New ACL Group") : _("Edit ACL Group")
      contents = HBox(
        HWeight(30, RichText(Id("help_text"), "")),
        HWeight(
          70,
          VBox(
            Label(label),
            VSpacing(0.5),
            TextEntry(Id("name"), _("Name"), ""),
            Left(
              ComboBox(
                Id("type"),
                Opt(:notify),
                _("Type"),
                SquidACL.GetTypesToComboBox
              )
            ),
            ReplacePoint(Id(:replace_point), Empty()),
            VStretch(),
            ButtonBox(
              PushButton(Id(:ok), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            )
          )
        )
      )

      UI.OpenDialog(contents)

      InitAddEditACLDialog(id_item)

      orig_type = Convert.to_string(UI.QueryWidget(Id("type"), :Value))
      SquidACL.Replace(:replace_point, orig_type)
      SquidACL.InitWidget(orig_type, id_item, "help_text")

      loop do
        ui = UI.UserInput

        if ui == :cancel || ui == :abort
          ret = false
          break
        elsif ui == :ok
          if StoreDataFromAddEditACLDialog(id_item)
            ret = true
            break
          end
        elsif ui == "type"
          type = Convert.to_string(UI.QueryWidget(Id("type"), :Value))
          SquidACL.Replace(:replace_point, type)
          if type == orig_type
            SquidACL.InitWidget(type, id_item, "help_text")
          else
            SquidACL.InitWidget(type, nil, "help_text")
          end
        end
      end

      UI.CloseDialog

      ret
    end
  end
end
