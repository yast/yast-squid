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

# File:	modules/SquidACL.ycp
# Package:	Configuration of squid
# Summary:	Definition and handling of ACL groups in Squid configuration
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id$
require "yast"

module Yast
  class SquidACLClass < Module
    def main
      Yast.import "UI"
      textdomain "squid"

      Yast.include self, "squid/SquidACL_local_functions.rb"

      # **
      # Unsupported ACLS:
      # * * * * * * * * * * *
      # ident, ident_regex,
      # src_as, dst_as,
      # proxy_auth, proxy_auth_regex,
      # snmp_community,
      # max_user_ip,
      # external,
      # urllogin, urlgroup
      # user_cert, ca_cert
      # ext_user

      # map of acl definition. format:
      #  $[
      #      "type" : $[ "name" : "Name shown in dialogs",
      #                  "widget" : `WidgetDescribingThisType,
      #                  "widget_init" : FunctionWithInitsOfWidget,
      #                  "verification" : FunctionCalledToVerificateContentsOfWidget,
      #                  "options" : FunctionThatReturnsListOfOptions
      #                 ]
      #  ]
      #
      #  widget_init prototype: void FuncName(integer id_item)
      #  verification prototype: boolean FuncName()
      #  options prototype: list<string> FuncName()
      @acl_map = {
        "src"           => {
          "name"         => "src",
          "widget"       => Frame(
            _("src"),
            VBox(
              # `TextEntry(`id("acl_addr1"), _("IP Address 1"), ""),
              # `Label(" - "),
              TextEntry(
                Id("acl_addr"),
                _("IP Address or Range of IP Addresses"),
                ""
              ),
              # `Label("/"),
              TextEntry(Id("acl_mask"), _("Network Mask"), "")
            )
          ),
          "widget_init"  => fun_ref(method(:srcWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:srcVerif), "boolean ()"),
          "options"      => fun_ref(method(:srcOptions), "list <string> ()"),
          "help"         => _("The IP address of the requesting client.")
        },
        "dst"           => {
          "name"         => "dst",
          "widget"       => Frame(
            _("dst"),
            VBox(
              TextEntry(Id("acl_addr"), _("IP Address"), ""),
              TextEntry(Id("acl_mask"), _("Network Mask"), "")
            )
          ),
          "widget_init"  => fun_ref(method(:dstWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:dstVerif), "boolean ()"),
          "options"      => fun_ref(method(:dstOptions), "list <string> ()"),
          "help"         => _("Destination IP Address.")
        },
        "myip"          => {
          "name"         => "myip",
          "widget"       => Frame(
            _("myip"),
            VBox(
              TextEntry(Id("acl_addr"), _("Local IP Address"), ""),
              TextEntry(Id("acl_mask"), _("Network Mask"), "")
            )
          ),
          "widget_init"  => fun_ref(method(:dstWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:dstVerif), "boolean ()"),
          "options"      => fun_ref(method(:dstOptions), "list <string> ()"),
          "help"         => _(
            "The local IP address on which the client connection exists."
          )
        },
        "srcdomain"     => {
          "name"         => "srcdomain",
          "widget"       => Frame(
            _("srcdomain"),
            VBox(TextEntry(Id("acl_domain"), _("Clients Domain Name"), ""))
          ),
          "widget_init"  => fun_ref(
            method(:srcdomainWidgetInit),
            "void (integer)"
          ),
          "verification" => fun_ref(method(:srcdomainVerif), "boolean ()"),
          "options"      => fun_ref(
            method(:srcdomainOptions),
            "list <string> ()"
          ),
          "help"         => _("This type matches the client's domain name.")
        },
        "dstdomain"     => {
          "name"         => "dstdomain",
          "widget"       => Frame(
            _("dstdomain"),
            VBox(TextEntry(Id("acl_domain"), _("Destination Domain"), ""))
          ),
          "widget_init"  => fun_ref(
            method(:srcdomainWidgetInit),
            "void (integer)"
          ),
          "verification" => fun_ref(method(:srcdomainVerif), "boolean ()"),
          "options"      => fun_ref(
            method(:srcdomainOptions),
            "list <string> ()"
          ),
          "help"         => _(
            "This refers to the destination domain, i.e. the source domain where the origin server is located."
          )
        },
        "srcdom_regex"  => regexp(
          "srcdom_regex",
          "srcdom_regex",
          _("Matches the client domain name.")
        ),
        "dstdom_regex"  => regexp(
          "dstdom_regex",
          "dstdom_regex",
          _("Provides match for destination domain.")
        ),
        "time"          => {
          "name"         => "time",
          "widget"       => Frame(
            _("time"),
            VBox(
              HWeight(
                1,
                MinHeight(
                  8,
                  MultiSelectionBox(
                    Id("acl_days"),
                    _("Days"),
                    [
                      Item(Id("M"), _("Monday")),
                      Item(Id("T"), _("Tuesday")),
                      Item(Id("W"), _("Wednesday")),
                      Item(Id("H"), _("Thursday")),
                      Item(Id("F"), _("Friday")),
                      Item(Id("A"), _("Saturday")),
                      Item(Id("S"), _("Sunday"))
                    ]
                  )
                )
              ),
              HWeight(
                1,
                HBox(
                  TextEntry(
                    Id("acl_from"),
                    Opt(:shrinkable),
                    _("From (H:M)"),
                    ""
                  ),
                  TextEntry(Id("acl_to"), Opt(:shrinkable), _("To (H:M)"), "")
                )
              )
            )
          ),
          "widget_init"  => fun_ref(method(:timeWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:timeVerif), "boolean ()"),
          "options"      => fun_ref(method(:timeOptions), "list <string> ()"),
          "help"         => ""
        },
        "url_regex"     => regexp(
          "url_regex",
          "url_regex",
          _("Matches using a regular expression on the complete URL.")
        ),
        "urlpath_regex" => regexp(
          "urlpath_regex",
          "urlpath_regex",
          _(
            "Matches the URL path minus any protocol, port, and host name information"
          )
        ),
        "port"          => {
          "name"         => "port",
          "widget"       => Frame(
            _("port"),
            TextEntry(Id("acl_port"), _("Port Number or Range of Ports"), "")
          ),
          "widget_init"  => fun_ref(method(:portWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:portVerif), "boolean ()"),
          "options"      => fun_ref(method(:portOptions), "list <string> ()"),
          "help"         => _("Matches the destination port for the request.")
        },
        "myport"        => {
          "name"         => "myport",
          "widget"       => Frame(
            _("myport"),
            TextEntry(Id("acl_port"), _("Port Number"), "")
          ),
          "widget_init"  => fun_ref(method(:myportWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:myportVerif), "boolean ()"),
          "options"      => fun_ref(method(:portOptions), "list <string> ()"),
          "help"         => _("Provides match for local TCP port number.")
        },
        "proto"         => {
          "name"         => "proto",
          "widget"       => Frame(
            _("proto"),
            TextEntry(Id("acl_proto"), _("Protocol"), "")
          ),
          "widget_init"  => fun_ref(method(:protoWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:protoVerif), "boolean ()"),
          "options"      => fun_ref(method(:protoOptions), "list <string> ()"),
          "help"         => _("Matches the protocol of the request.")
        },
        "method"        => {
          "name"         => "method",
          "widget"       => Frame(
            _("method"),
            ComboBox(
              Id("acl_method"),
              _("HTTP Method"),
              [
                Item(Id("GET"), "GET"),
                Item(Id("HEAD"), "HEAD"),
                Item(Id("POST"), "POST"),
                Item(Id("PUT"), "PUT"),
                Item(Id("DELETE"), "DELETE"),
                Item(Id("TRACE"), "TRACE"),
                Item(Id("CONNECT"), "CONNECT")
              ]
            )
          ),
          "widget_init"  => fun_ref(method(:methodWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:methodVerif), "boolean ()"),
          "options"      => fun_ref(method(:methodOptions), "list <string> ()"),
          "help"         => _(
            "This type matches the HTTP method in the request headers."
          )
        },
        "browser"       => regexp(
          "browser",
          "browser",
          _(
            "A regular expression that matches the client's browser type based on the user agent header."
          )
        ),
        "maxconn"       => {
          "name"         => "maxconn",
          "widget"       => Frame(
            "maxconn",
            IntField(
              Id("acl_connections"),
              _("Maximum Number of HTTP Connections"),
              0,
              999999,
              0
            )
          ),
          "widget_init"  => fun_ref(
            method(:maxconnWidgetInit),
            "void (integer)"
          ),
          "verification" => fun_ref(method(:maxconnVerif), "boolean ()"),
          "options"      => fun_ref(method(:maxconnOptions), "list <string> ()"),
          "help"         => _(
            "Matches when the client's IP address has more than the specified number of HTTP connections established."
          )
        },
        "referer_regex" => regexp(
          "referer_regex",
          "referer_regex",
          _("Matches Referer header.")
        ),
        "req_header"    => {
          "name"         => "req_header",
          "widget"       => Frame(
            "req_header",
            VBox(
              TextEntry(Id("acl_header_name"), _("Header Name"), ""),
              TextEntry(Id("acl_regexp"), _("Regular Expression(s)"), ""),
              Left(
                CheckBox(
                  Id("acl_regexp_case_insensitive"),
                  _("Case Insensitive"),
                  false
                )
              )
            )
          ),
          "widget_init"  => fun_ref(method(:headerWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:headerVerif), "boolean ()"),
          "options"      => fun_ref(method(:headerOptions), "list <string> ()"),
          "help"         => _(
            "Regular expression matching any of the known request headers."
          )
        },
        "rep_header"    => {
          "name"         => "rep_header",
          "widget"       => Frame(
            "rep_header",
            VBox(
              TextEntry(Id("acl_header_name"), _("Header Name"), ""),
              TextEntry(Id("acl_regexp"), _("Regular Expression(s)"), ""),
              Left(
                CheckBox(
                  Id("acl_regexp_case_insensitive"),
                  _("Case Insensitive"),
                  false
                )
              )
            )
          ),
          "widget_init"  => fun_ref(method(:headerWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:headerVerif), "boolean ()"),
          "options"      => fun_ref(method(:headerOptions), "list <string> ()"),
          "help"         => _(
            "Regular expression matching the mime type of the reply received by squid. Can\nbe used to detect file download or some types of HTTP tunnelling requests.\n"
          )
        },
        "req_mime_type" => regexp(
          "req_mime_type",
          "req_mime_type",
          _("Match the mime type of the request generated by the client.")
        ),
        "rep_mime_type" => regexp(
          "rep_mime_type",
          "rep_mime_type",
          _("Match the mime type of the reply received by Squid.")
        ),
        "arp"           => {
          "name"         => "arp",
          "widget"       => Frame(
            "arp",
            TextEntry(Id("acl_mac"), _("MAC Address"), "")
          ),
          "widget_init"  => fun_ref(method(:arpWidgetInit), "void (integer)"),
          "verification" => fun_ref(method(:arpVerif), "boolean ()"),
          "options"      => fun_ref(method(:arpOptions), "list <string> ()"),
          "help"         => _("Ethernet (MAC) address matching.")
        }
      }

      # List of available acls.
      # Also specify order of acls.
      # Values must corespond with keys in acl_map.
      @acl = Builtins.sort(getKeys(@acl_map))
    end

    def getKeys(m)
      m = deep_copy(m)
      ret = []
      Builtins.foreach(m) { |key, _value| ret = Builtins.add(ret, key) }
      deep_copy(ret)
    end

    # Returns list of supported ACLs.
    # It's necessary to have saved unsupported ACLs but do not handle with them.
    def SupportedACLs
      deep_copy(@acl)
    end

    # Returns list of terms in form:
    #      [ `item(`id(key), acl_map[key]["name"]:""), `item(... ) ]
    # Returned list is preferably to place in UI::ComboBox as list of
    # all available types of ACLs.
    def GetTypesToComboBox
      items = []

      Builtins.foreach(@acl) do |value|
        items = Builtins.add(
          items,
          Item(
            Id(value),
            Ops.get_string(Ops.get(@acl_map, value, {}), "name", "")
          )
        )
      end

      deep_copy(items)
    end

    # Initialize widget of acl identified by id_acl_type.
    # If id_item is not nil, function initialize widgets by default values
    # from module Squid.
    def InitWidget(id_acl_type, id_item, help_widget_id)
      help_widget_id = deep_copy(help_widget_id)
      if !help_widget_id.nil?
        UI.ChangeWidget(
          Id(help_widget_id),
          :Value,
          Ops.get_string(Ops.get(@acl_map, id_acl_type, {}), "help", "")
        )
      end
      func = Convert.convert(
        Ops.get(Ops.get(@acl_map, id_acl_type, {}), "widget_init"),
        from: "any",
        to:   "void (integer)"
      )
      func.call(id_item)

      nil
    end

    # Replace widget with id widget_id by widget acl_map[id_acl_type]["widget"].
    def Replace(widget_id, id_acl_type)
      widget_id = deep_copy(widget_id)
      UI.ReplaceWidget(
        Id(widget_id),
        Ops.get_term(Ops.get(@acl_map, id_acl_type, {}), "widget", Empty())
      )

      nil
    end

    # This function call verification function joined with acl type
    # identified by id_acl_type.
    # Returns return value of verification function.
    def Verify(id_acl_type)
      func = Convert.convert(
        Ops.get(Ops.get(@acl_map, id_acl_type, {}), "verification"),
        from: "any",
        to:   "boolean ()"
      )
      func.call
    end

    # Returns values from widget as list of options in correct form to store
    # them into Squid module.
    def GetOptions(id_acl_type)
      func = Convert.convert(
        Ops.get(Ops.get(@acl_map, id_acl_type, {}), "options"),
        from: "any",
        to:   "list <string> ()"
      )
      func.call
    end

    publish function: :SupportedACLs, type: "list <string> ()"
    publish function: :GetTypesToComboBox, type: "list <term> ()"
    publish function: :InitWidget, type: "void (string, integer, any)"
    publish function: :Replace, type: "void (any, string)"
    publish function: :Verify, type: "boolean (string)"
    publish function: :GetOptions, type: "list <string> (string)"
  end

  SquidACL = SquidACLClass.new
  SquidACL.main
end
