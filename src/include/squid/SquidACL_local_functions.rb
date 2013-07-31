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

# File:	include/squid/SquidACL_local_functions.ycp
# Package:	Configuration of squid
# Summary:	Non-global functions of SquidACL module which are linked with acl_map variable.
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id$
module Yast
  module SquidSquidACLLocalFunctionsInclude
    def initialize_squid_SquidACL_local_functions(include_target)
      Yast.import "UI"

      textdomain "squid"
      Yast.import "Report"

      Yast.import "Squid"

      Yast.include include_target, "squid/helper_functions.rb"
    end

    def splitToChars(str)
      len = Builtins.size(str)
      i = 0
      ret = []
      while Ops.less_than(i, len)
        ret = Builtins.add(ret, Builtins.substring(str, i, 1))
        i = Ops.add(i, 1)
      end

      deep_copy(ret)
    end

    def isMask(str)
      Builtins.regexpmatch(str, "^[0-9]+$") || isIPAddr(str)
    end
    def isHHMMFormat(str)
      return false if !Builtins.regexpmatch(str, "^[0-9]{1,2}:[0-9]{1,2}$")
      hm = Builtins.splitstring(str, ":")
      tmp = 0

      tmp = Builtins.tointeger(Ops.get(hm, 0, ""))
      return false if Ops.less_than(tmp, 0) || Ops.greater_than(tmp, 23)
      tmp = Builtins.tointeger(Ops.get(hm, 1, ""))
      return false if Ops.less_than(tmp, 0) || Ops.greater_than(tmp, 59)

      true
    end
    def isCorrectFromTo(from, to)
      fr = Builtins.tointeger(
        Builtins.regexpsub(
          Builtins.mergestring(Builtins.splitstring(from, ":"), ""),
          "([1-9][0-9]*$)",
          "\\1"
        )
      )
      t = Builtins.tointeger(
        Builtins.regexpsub(
          Builtins.mergestring(Builtins.splitstring(to, ":"), ""),
          "([1-9][0-9]*$)",
          "\\1"
        )
      )

      Ops.less_than(fr, t)
    end



    def widgetInitIPAddr(id)
      id = deep_copy(id)
      UI.ChangeWidget(Id(id), :ValidChars, "1234567890.")

      nil
    end
    def widgetInitMask(id)
      id = deep_copy(id)
      UI.ChangeWidget(Id(id), :ValidChars, "1234567890.")

      nil
    end
    def widgetInitDomainName(id)
      id = deep_copy(id)
      UI.ChangeWidget(
        Id(id),
        :ValidChars,
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ."
      )

      nil
    end
    def widgetInitHHMM(id)
      id = deep_copy(id)
      UI.ChangeWidget(Id(id), :ValidChars, "1234567890:")
      UI.ChangeWidget(Id(id), :InputMaxLength, 5)

      nil
    end


    #*****************  SRC  ************************
    def srcWidgetInit(id_item)
      UI.ChangeWidget(Id("acl_addr"), :ValidChars, "1234567890.-")
      widgetInitMask("acl_mask")

      if id_item != nil
        acl = Squid.GetACL(id_item)
        data = Builtins.splitstring(
          Ops.get(Ops.get_list(acl, "options", []), 0, ""),
          "/"
        )

        UI.ChangeWidget(Id("acl_addr"), :Value, Ops.get(data, 0, ""))
        UI.ChangeWidget(Id("acl_mask"), :Value, Ops.get(data, 1, ""))
      end

      nil
    end

    def srcVerif
      ok = true
      addr = Convert.to_string(UI.QueryWidget(Id("acl_addr"), :Value))
      mask = Convert.to_string(UI.QueryWidget(Id("acl_mask"), :Value))
      tmp = Builtins.splitstring(addr, "-")

      if Builtins.size(addr) == 0 ||
          !isIPAddr(addr) && !isIPAddr(Ops.get(tmp, 0, "")) &&
            !isIPAddr(Ops.get(tmp, 1, "")) ||
          Ops.greater_than(Builtins.size(mask), 0) && !isMask(mask)
        ok = false
        Report.Error(_("Invalid values."))
      end
      ok
    end

    def srcOptions
      data = []
      addr = Convert.to_string(UI.QueryWidget(Id("acl_addr"), :Value))
      mask = Convert.to_string(UI.QueryWidget(Id("acl_mask"), :Value))

      Ops.set(data, 0, addr)
      if Ops.greater_than(Builtins.size(mask), 0) &&
          Ops.greater_than(Builtins.size(addr), 0)
        Ops.set(data, 0, Ops.add(Ops.add(Ops.get(data, 0, ""), "/"), mask))
      end
      deep_copy(data)
    end
    #*****************  SRC END  ********************


    #*****************  DST  ************************
    def dstWidgetInit(id_item)
      widgetInitIPAddr("acl_addr")
      widgetInitMask("acl_mask")

      if id_item != nil
        acl = Squid.GetACL(id_item)
        data = Builtins.splitstring(
          Ops.get(Ops.get_list(acl, "options", []), 0, ""),
          "/"
        )

        UI.ChangeWidget(Id("acl_addr"), :Value, Ops.get(data, 0, ""))
        UI.ChangeWidget(Id("acl_mask"), :Value, Ops.get(data, 1, ""))
      end

      nil
    end

    def dstVerif
      ok = true
      addr = Convert.to_string(UI.QueryWidget(Id("acl_addr"), :Value))
      mask = Convert.to_string(UI.QueryWidget(Id("acl_mask"), :Value))

      if !isIPAddr(addr) ||
          Ops.greater_than(Builtins.size(mask), 0) && !isMask(mask)
        ok = false
        Report.Error(_("Invalid values."))
      end
      ok
    end

    def dstOptions
      data = []
      addr = Convert.to_string(UI.QueryWidget(Id("acl_addr"), :Value))
      mask = Convert.to_string(UI.QueryWidget(Id("acl_mask"), :Value))

      Ops.set(data, 0, addr)
      if Ops.greater_than(Builtins.size(mask), 0) &&
          Ops.greater_than(Builtins.size(addr), 0)
        Ops.set(data, 0, Ops.add(Ops.add(Ops.get(data, 0, ""), "/"), mask))
      end
      deep_copy(data)
    end
    #*****************  DST END  ********************


    # *****************  MYIP  ************************
    #  * Uses same functions as DST
    # /******************  MYIP END  *******************


    #***************  SRCDOMAIN  ********************
    def srcdomainWidgetInit(id_item)
      widgetInitDomainName("acl_domain")

      if id_item != nil
        acl = Squid.GetACL(id_item)
        UI.ChangeWidget(
          Id("acl_domain"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    def srcdomainVerif
      ok = true

      if Builtins.size(
          Convert.to_string(UI.QueryWidget(Id("acl_domain"), :Value))
        ) == 0
        ok = false
        Report.Error(_("Domain Name must not be empty."))
      end
      ok
    end
    def srcdomainOptions
      [Convert.to_string(UI.QueryWidget(Id("acl_domain"), :Value))]
    end
    #***************  SRCDOMAIN END  ****************

    # ***************  DSTDOMAIN  *********************
    #  * Uses same functions as SRCDOMAIN.
    # /****************  DSTDOMAIN END  ****************


    #***************  REGEXP  ***********************
    # Returns universal widget for setting a regular expression.
    def regexpWidget(frame_title)
      Frame(
        frame_title,
        VBox(
          TextEntry(Id("acl_regexp"), _("Regular Expression"), ""),
          Left(
            CheckBox(
              Id("acl_regexp_case_insensitive"),
              _("Case Insensitive"),
              false
            )
          )
        )
      )
    end

    # Universal widget_init for regular expression.
    def regexpWidgetInit(id_item)
      if id_item != nil
        acl = Squid.GetACL(id_item)

        if Ops.get(Ops.get_list(acl, "options", []), 0, "") == "-i"
          UI.ChangeWidget(Id("acl_regexp_case_insensitive"), :Value, true)
          Ops.set(
            acl,
            "options",
            Builtins.remove(Ops.get_list(acl, "options", []), 0)
          )
        end
        UI.ChangeWidget(
          Id("acl_regexp"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    # Universal verification function for regular expression.
    def regexpVerif
      ok = true
      regexp = Convert.to_string(UI.QueryWidget(Id("acl_regexp"), :Value))

      if Builtins.size(regexp) == 0
        ok = false
        Report.Error(_("Regular Expression must not be empty."))
      end
      ok
    end
    # Universal options function for regular expression.
    def regexpOptions
      ret = []
      if Convert.to_boolean(
          UI.QueryWidget(Id("acl_regexp_case_insensitive"), :Value)
        )
        Ops.set(ret, 0, "-i")
      end
      ret = Builtins.add(
        ret,
        Convert.to_string(UI.QueryWidget(Id("acl_regexp"), :Value))
      )
      deep_copy(ret)
    end

    # Returns map describing acl which has type of regular expression.
    def regexp(name, frame_title, help)
      {
        "name"         => name,
        "widget"       => regexpWidget(frame_title),
        "widget_init"  => fun_ref(method(:regexpWidgetInit), "void (integer)"),
        "verification" => fun_ref(method(:regexpVerif), "boolean ()"),
        "options"      => fun_ref(method(:regexpOptions), "list <string> ()"),
        "help"         => help
      }
    end
    #***************  REGEXP END  *******************



    #***************  TIME  *************************
    def timeWidgetInit(id_item)
      widgetInitHHMM("acl_from")
      widgetInitHHMM("acl_to")

      if id_item != nil
        acl = Squid.GetACL(id_item)
        days = splitToChars(Ops.get(Ops.get_list(acl, "options", []), 0, ""))
        times = Builtins.splitstring(
          Ops.get(Ops.get_list(acl, "options", []), 1, ""),
          "-"
        )

        UI.ChangeWidget(Id("acl_days"), :SelectedItems, days)
        UI.ChangeWidget(Id("acl_from"), :Value, Ops.get(times, 0, ""))
        UI.ChangeWidget(Id("acl_to"), :Value, Ops.get(times, 1, ""))
      end

      nil
    end
    def timeVerif
      ok = true
      from = Convert.to_string(UI.QueryWidget(Id("acl_from"), :Value))
      to = Convert.to_string(UI.QueryWidget(Id("acl_to"), :Value))
      selected_items = Builtins.size(
        Convert.to_list(UI.QueryWidget(Id("acl_days"), :SelectedItems))
      )

      if selected_items == 0
        ok = false
        Report.Error(_("You must select at least one day."))
      elsif !isHHMMFormat(from) || !isHHMMFormat(to)
        ok = false
        Report.Error(_("Time is not set in correct format."))
      elsif !isCorrectFromTo(from, to)
        ok = false
        Report.Error(_("From must be less than To.")) #TODO: better error message
      end
      ok
    end
    def timeOptions
      days = Builtins.mergestring(
        Convert.convert(
          UI.QueryWidget(Id("acl_days"), :SelectedItems),
          :from => "any",
          :to   => "list <string>"
        ),
        ""
      )
      times = Builtins.mergestring(
        [
          Convert.to_string(UI.QueryWidget(Id("acl_from"), :Value)),
          Convert.to_string(UI.QueryWidget(Id("acl_to"), :Value))
        ],
        "-"
      )
      [days, times]
    end
    #***************  TIME END  *********************


    #***************  PORT  *************************
    def portWidgetInit(id_item)
      UI.ChangeWidget(Id("acl_port"), :ValidChars, "1234567890-")

      if id_item != nil
        acl = Squid.GetACL(id_item)

        UI.ChangeWidget(
          Id("acl_port"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    def portVerif
      ok = true
      port = Convert.to_string(UI.QueryWidget(Id("acl_port"), :Value))

      if !Builtins.regexpmatch(port, "^[0-9]+(-[0-9]+){0,1}$")
        ok = false
      else
        ports = Builtins.splitstring(port, "-")
        if Builtins.size(ports) == 2 &&
            Ops.greater_than(
              Builtins.tointeger(Ops.get(ports, 0, "")),
              Builtins.tointeger(Ops.get(ports, 1, ""))
            )
          ok = false
        end
      end
      Report.Error(_("Invalid value.")) if !ok
      ok
    end
    def portOptions
      [Convert.to_string(UI.QueryWidget(Id("acl_port"), :Value))]
    end
    #***************  PORT END  *********************


    #*************  MYPORT  *************************
    def myportWidgetInit(id_item)
      UI.ChangeWidget(Id("acl_port"), :ValidChars, "1234567890")

      if id_item != nil
        acl = Squid.GetACL(id_item)

        UI.ChangeWidget(
          Id("acl_port"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    def myportVerif
      ok = true
      port = Convert.to_string(UI.QueryWidget(Id("acl_port"), :Value))

      if !Builtins.regexpmatch(port, "^[0-9]+$")
        ok = false
        Report.Error(_("Invalid value."))
      end
      ok
    end
    #*************  MYPORT END  *********************


    #**************  PROTO  *************************
    def protoWidgetInit(id_item)
      UI.ChangeWidget(
        Id("acl_proto"),
        :ValidChars,
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
      )

      if id_item != nil
        acl = Squid.GetACL(id_item)

        UI.ChangeWidget(
          Id("acl_proto"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    def protoVerif
      ok = true
      protocol = Convert.to_string(UI.QueryWidget(Id("acl_proto"), :Value))

      if Builtins.size(protocol) == 0
        Report.Error(_("Protocol must not be empty."))
      end
      ok
    end
    def protoOptions
      [Convert.to_string(UI.QueryWidget(Id("acl_proto"), :Value))]
    end
    #**************  PROTO END  *********************


    #**************  METHOD  ************************
    def methodWidgetInit(id_item)
      if id_item != nil
        acl = Squid.GetACL(id_item)

        UI.ChangeWidget(
          Id("acl_method"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    def methodVerif
      true
    end
    def methodOptions
      [Convert.to_string(UI.QueryWidget(Id("acl_method"), :Value))]
    end
    #**************  METHOD END  ********************


    #**************  MAXCONN  ***********************
    def maxconnWidgetInit(id_item)
      if id_item != nil
        acl = Squid.GetACL(id_item)

        UI.ChangeWidget(
          Id("acl_connections"),
          :Value,
          Builtins.tointeger(Ops.get(Ops.get_list(acl, "options", []), 0, ""))
        )
      end

      nil
    end
    def maxconnVerif
      true
    end
    def maxconnOptions
      [Builtins.tostring(UI.QueryWidget(Id("acl_connections"), :Value))]
    end
    #**************  MAXCONN END  *******************


    #**************  HEADER  ************************
    def headerWidgetInit(id_item)
      if id_item != nil
        acl = Squid.GetACL(id_item)
        UI.ChangeWidget(
          Id("acl_header_name"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
        if Ops.get(Ops.get_list(acl, "options", []), 1, "") == "-i"
          UI.ChangeWidget(
            Id("acl_regexp"),
            :Value,
            Ops.get(Ops.get_list(acl, "options", []), 2, "")
          )
          UI.ChangeWidget(Id("acl_regexp_case_insensitive"), :Value, true)
        else
          UI.ChangeWidget(
            Id("acl_regexp"),
            :Value,
            Ops.get(Ops.get_list(acl, "options", []), 1, "")
          )
        end
      end

      nil
    end
    def headerVerif
      ok = true
      header_name = Convert.to_string(
        UI.QueryWidget(Id("acl_header_name"), :Value)
      )
      regexp = Convert.to_string(UI.QueryWidget(Id("acl_regexp"), :Value))

      if Builtins.size(header_name) == 0 && Builtins.size(regexp) == 0
        ok = false
        Report.Error(_("Header Name and Regular Expression must not be empty."))
      end
      ok
    end
    def headerOptions
      header_name = Convert.to_string(
        UI.QueryWidget(Id("acl_header_name"), :Value)
      )
      regexp = Convert.to_string(UI.QueryWidget(Id("acl_regexp"), :Value))
      ci = Convert.to_boolean(
        UI.QueryWidget(Id("acl_regexp_case_insensitive"), :Value)
      )
      ret = [header_name]

      ret = Builtins.add(ret, "-i") if ci == true
      ret = Builtins.add(ret, regexp)

      deep_copy(ret)
    end
    #**************  HEADER END  ********************


    #**************  ARP  ***************************
    def arpWidgetInit(id_item)
      UI.ChangeWidget(Id("acl_mac"), :ValidChars, "1234567890ABCDEFabcdef:")

      if id_item != nil
        acl = Squid.GetACL(id_item)
        UI.ChangeWidget(
          Id("acl_mac"),
          :Value,
          Ops.get(Ops.get_list(acl, "options", []), 0, "")
        )
      end

      nil
    end
    def arpVerif
      ok = true
      mac = Convert.to_string(UI.QueryWidget(Id("acl_mac"), :Value))
      if Builtins.size(mac) == 0
        ok = false
        # error report
        Report.Error(_("MAC Address must not be empty."))
      elsif !Builtins.regexpmatch(mac, "^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$")
        ok = false
        # error report
        Report.Error(_("Incorrect format of MAC Address."))
      end
      ok
    end
    def arpOptions
      [Convert.to_string(UI.QueryWidget(Id("acl_mac"), :Value))]
    end
  end
end
