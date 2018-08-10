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

# File:	modules/Squid.ycp
# Package:	Configuration of squid
# Summary:	Squid settings, input and output functions
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: Squid.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# Representation of the configuration of squid.
# Input and output routines.

require "yast"
require "y2firewall/firewalld"
require "yast2/system_service"

module Yast
  class SquidClass < Module
    def main
      textdomain "squid"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Service"
      Yast.import "FileUtils"

      # Defines path used in SCR::Read/Write functions
      @squid_path = path(".etc.squid")

      # Defines name of service which is used by firewall when it's openning ports.
      @firewall_service_name = "squid"


      # Data was modified?
      @modified = false

      # Is service enabled?
      @service_enabled_on_startup = false


      # Map of all configuration settings except consequential. Format:
      # $[ "parameter name" : [ list of options (rest of line) ]
      #    ...
      # ]
      @settings = {}

      # List of http_ports. Format:
      # [ $["host" : "hostname",
      #     "port" : "3128",
      #     "transparent" : true],
      #     ...
      # ]
      @http_ports = []

      # List of acls. Format:
      # [ $[ "name" : "localhost",
      #      "type" : "src",
      #      "options" : [ non-empty list of options ]]
      #      ...
      # ]
      @acls = []

      # List of access control parameters. Format:
      # [ $["allow" : true,
      #     "acl" : ["acl1", "!acl2", ...] ],
      #     ...
      # ]
      @http_accesses = []

      # List of refresh patterns. Format:
      # [ $["regexp" : "^ftp:",
      #     "case_sensitive" : true,
      #     "min" : "12",
      #     "max" : "12",
      #     "percent" : "12"],
      #     ...
      # ]
      @refresh_patterns = []


      # Map of all available parameters with defalut values.
      # $[ "parameter_name" : [ list of default options ],
      #    ...
      #  ]
      @parameters = {
        "cache_dir"                 => [
          "ufs",
          "/var/cache/squid",
          "100",
          "16",
          "256"
        ],
        "cache_mem"                 => ["8", "MB"],
        "cache_swap_low"            => ["90"],
        "cache_swap_high"           => ["95"],
        "maximum_object_size"       => ["4096", "KB"],
        "minimum_object_size"       => ["0", "KB"],
        "cache_replacement_policy"  => ["lru"],
        "memory_replacement_policy" => ["lru"],
        "access_log"                => ["/var/log/squid/access.log"],
        "cache_log"                 => ["/var/log/squid/cache.log"],
        "cache_store_log"           => ["/var/log/squid/store.log"],
        "connect_timeout"           => ["2", "minutes"],
        "client_lifetime"           => ["1", "days"],
        "error_directory"           => ["/usr/share/squid/errors/en"],
        "cache_mgr"                 => ["webmaster"],
        "ftp_passive"               => ["on"]
      }



      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      #global boolean() AbortFunction = GetModified;
      @AbortFunction = nil
    end

    def GetFirewallServiceName
      @firewall_service_name
    end

    #****************  HELP FUNCTIONS  **************
    # Same as splitstring(), but returns only non-empty strings.
    def split(str, delim)
      Builtins.filter(Builtins.splitstring(str, delim)) do |value|
        Ops.greater_than(Builtins.size(value), 0)
      end
    end
    # Verify and repair list of ACLs if something's wrong.
    def verifyACLs
      #verification of ACLs
      #There must not exist more ACLs with same name and different type
      i = 0
      tested = []
      to_remove = []
      ii = 0
      Builtins.foreach(@acls) do |value|
        if !Builtins.contains(tested, Ops.get_string(value, "name", ""))
          if Ops.greater_than(NumACLs(i), 0)
            to_remove = []
            ii = 0
            Builtins.foreach(@acls) do |val|
              if Ops.get_string(val, "name", "") ==
                  Ops.get_string(value, "name", "") &&
                  Ops.get_string(val, "type", "") !=
                    Ops.get_string(value, "type", "")
                to_remove = Builtins.add(to_remove, ii)
              end
              ii = Ops.add(ii, 1)
            end
            #delete all ACLs which has not type same as value["type"]:"" -
            # - it means type of first occurence of tested ACL
            Builtins.foreach(to_remove) do |val|
              @acls = Builtins.remove(@acls, val)
            end
          end
          tested = Builtins.add(tested, Ops.get_string(value, "name", ""))
        end
        i = Ops.add(i, 1)
      end

      nil
    end


    def repairTimeoutPeriodUnits(old)
      ret = "seconds"
      if old == "day"
        ret = "days"
      elsif old == "hour"
        ret = "hours"
      elsif old == "minute"
        ret = "minutes"
      elsif old == "second"
        ret = "seconds"
      elsif Builtins.contains(["seconds", "minutes", "hours", "days"], old)
        ret = old
      end

      ret
    end


    # Function which sets permissions 'chmod 750' and 'chown squid:root'
    # to directory dir if exists.
    # If dir does not exist, function returns true;
    def setWritePremissionsToCacheDir(dir)
      if !FileUtils.IsDirectory(dir)
        Builtins.y2debug(
          "Squid::checkWritePremissionsCacheDir() - '%1' is not directory",
          dir
        )
        return true
      end

      if Convert.to_integer(
          SCR.Execute(path(".target.bash"), Ops.add("chown squid:root ", dir))
        ) != 0 ||
          Convert.to_integer(
            SCR.Execute(path(".target.bash"), Ops.add("chmod 750 ", dir))
          ) != 0
        return false
        #return (Popup::ContinueCancel(sformat(_("Unable to set correct permissions to directory %1."), dir)));
      end

      true
    end
    #****************  HELP FUNCTIONS END  **********





    def SetDefaultValues
      @http_ports = [{ "host" => "", "port" => "3128", "transparent" => false }]
      @acls = [
        {
          "name"    => "QUERY",
          "options" => ["cgi-bin \\?"],
          "type"    => "urlpath_regex"
        },
        {
          "name"    => "apache",
          "options" => ["Server", "^Apache"],
          "type"    => "rep_header"
        },
        { "name" => "all", "options" => ["0.0.0.0/0.0.0.0"], "type" => "src" },
        {
          "name"    => "manager",
          "options" => ["cache_object"],
          "type"    => "proto"
        },
        {
          "name"    => "localhost",
          "options" => ["127.0.0.1/255.255.255.255"],
          "type"    => "src"
        },
        {
          "name"    => "to_localhost",
          "options" => ["127.0.0.0/8"],
          "type"    => "dst"
        },
        { "name" => "SSL_ports", "options" => ["443"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["80"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["21"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["443"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["70"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["210"], "type" => "port" },
        {
          "name"    => "Safe_ports",
          "options" => ["1025-65535"],
          "type"    => "port"
        },
        { "name" => "Safe_ports", "options" => ["280"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["488"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["591"], "type" => "port" },
        { "name" => "Safe_ports", "options" => ["777"], "type" => "port" },
        { "name" => "CONNECT", "options" => ["CONNECT"], "type" => "method" }
      ]
      @http_accesses = [
        { "acl" => ["manager", "localhost"], "allow" => true },
        { "acl" => ["manager"], "allow" => false },
        { "acl" => ["!Safe_ports"], "allow" => false },
        { "acl" => ["CONNECT", "!SSL_ports"], "allow" => false },
        { "acl" => ["localhost"], "allow" => true },
        { "acl" => ["all"], "allow" => false }
      ]
      @refresh_patterns = [
        {
          "case_sensitive" => true,
          "max"            => "10080",
          "min"            => "1440",
          "percent"        => "20",
          "regexp"         => "^ftp:"
        },
        {
          "case_sensitive" => true,
          "max"            => "1440",
          "min"            => "1440",
          "percent"        => "0",
          "regexp"         => "^gopher:"
        },
        {
          "case_sensitive" => true,
          "max"            => "4320",
          "min"            => "0",
          "percent"        => "20",
          "regexp"         => "."
        }
      ]
      @settings = deep_copy(@parameters)
      @service_enabled_on_startup = false

      nil
    end



    def GetModified
      @modified
    end

    def SetModified
      Builtins.y2debug("Squid::SetModified() - Squid modified")
      @modified = true

      nil
    end

    # Abort function
    #
    # @return [Boolean] true if abort
    def Abort
      return false if @AbortFunction.nil?

      @AbortFunction.call
    end


    #****** SERVICE ******

    # @deprecated
    def IsServiceEnabled
      @service_enabled_on_startup
    end

    # @deprecated
    def SetServiceEnabled(enabled)
      SetModified()
      @service_enabled_on_startup = enabled

      nil
    end
    #****** SERVICE END  *

    #****** ACL ******
    def GetACLs
      deep_copy(@acls)
    end

    def GetACL(id_item)
      Ops.get(@acls, id_item, {})
    end

    def GetACLType(id_item)
      Ops.get_string(Ops.get(@acls, id_item, {}), "type", "")
    end

    def GetACLTypeByName(acl_name)
      ret = nil
      Builtins.foreach(@acls) do |value|
        if Ops.get_string(value, "name", "") == acl_name
          ret = Ops.get_string(value, "type", "")
          raise Break
        end
      end
      ret
    end

    def AddACL(name, type, options)
      options = deep_copy(options)
      SetModified()
      @acls = Builtins.add(
        @acls,
        { "name" => name, "type" => type, "options" => options }
      )

      nil
    end

    def ModifyACL(id_item, name, type, options)
      options = deep_copy(options)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@acls))
        tmp = { "name" => name, "type" => type, "options" => options }
        if tmp != Ops.get(@acls, id_item, {})
          SetModified()
          Ops.set(@acls, id_item, tmp)
        end
      end

      nil
    end

    def DelACL(id_item)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@acls))
        SetModified()
        @acls = Builtins.remove(@acls, id_item)
      end

      nil
    end


    # Returns number of occurences of ACL (definition lines) in config file.
    def NumACLs(id_item)
      acl = Ops.get_string(Ops.get(@acls, id_item, {}), "name", "") #get name of acl
      return nil if Builtins.size(acl) == 0 #invalid id_item
      ret = 0

      Builtins.foreach(@acls) do |value|
        ret = Ops.add(ret, 1) if Ops.get_string(value, "name", "") == acl
      end

      Builtins.y2debug("Squid::NumACLs() - acl: %1, num: %2", acl, ret)

      ret
    end

    # Same as NumACLs but ACL is identified by name.
    def NumACLsByName(name)
      ret = nil
      i = 0
      Builtins.foreach(@acls) do |value|
        raise Break if Ops.get_string(value, "name", "") == name
        i = Ops.add(i, 1)
      end
      ret = NumACLs(i) if Ops.less_than(i, Builtins.size(@acls))

      ret
    end

    # Returns list of options which use this ACL (identified by id_item).
    # It's necessary to run this function before deleting ACL to know if
    # any options are not affected.
    def ACLIsUsedBy(id_item)
      acl = Ops.get_string(GetACL(id_item), "name", "")
      return nil if Builtins.size(acl) == 0 #invalid id_item

      params = []
      ret = []

      # options with format:
      #      option_name something ACL ACL ACL ...
      format1 = [
        "no_cache",
        "cache",
        "broken_vary_encoding",
        "follow_x_forwarded_for",
        #"http_access", -> cached in this module !!!
        "http_reply_access",
        "icp_access",
        "htcp_access",
        "miss_access",
        "ident_lookup_access",
        "log_access",
        "always_direct",
        "never_direct",
        "snmp_access",
        "broken_posts",
        "deny_info"
      ]
      # options with format:
      #      option_name something something ACL ACL ACL ...
      format2 = [
        "tcp_outgoing_tos",
        "tcp_outgoing_address",
        "reply_body_max_size",
        "header_access",
        "cache_peer_access",
        "access_log"
      ]

      available_options = SCR.Dir(@squid_path)

      Builtins.foreach(
        Convert.convert(
          Builtins.merge(format1, format2),
          :from => "list",
          :to   => "list <string>"
        )
      ) do |value|
        if Builtins.contains(available_options, value)
          Builtins.foreach(
            Convert.convert(
              SCR.Read(Builtins.add(@squid_path, value)),
              :from => "any",
              :to   => "list <list <string>>"
            )
          ) do |params2|
            params2 = Builtins.remove(params2, 0) # remove first param
            if Builtins.contains(format2, value)
              if Ops.greater_than(Builtins.size(params2), 1)
                params2 = Builtins.remove(params2, 0)
              else
                raise Break
              end
            end
            if Builtins.contains(params2, acl) ||
                Builtins.contains(params2, Ops.add("!", acl))
              ret = Builtins.add(ret, value)
              raise Break
            end
          end
        end
      end

      #http_access:
      Builtins.foreach(@http_accesses) do |value|
        if Builtins.contains(Ops.get_list(value, "acl", []), acl) ||
            Builtins.contains(Ops.get_list(value, "acl", []), Ops.add("!", acl))
          ret = Builtins.add(ret, "http_access")
          raise Break
        end
      end

      Builtins.y2debug("Squid::ACLIsUsedBy() - acl:%1, ret: %2", acl, ret)

      deep_copy(ret)
    end
    #****** ACL END ******

    #****** HTTP_ACCESS *****
    def GetHttpAccesses
      deep_copy(@http_accesses)
    end

    def GetHttpAccess(id_item)
      Ops.get(@http_accesses, id_item, {})
    end

    def AddHttpAccess(allow, acl)
      acl = deep_copy(acl)
      SetModified()
      @http_accesses = Builtins.add(
        @http_accesses,
        { "allow" => allow, "acl" => acl }
      )

      nil
    end

    def ModifyHttpAccess(id_item, allow, acl)
      acl = deep_copy(acl)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@http_accesses))
        tmp = { "allow" => allow, "acl" => acl }

        if tmp != Ops.get(@http_accesses, id_item, {})
          SetModified()
          Ops.set(@http_accesses, id_item, tmp)
        end
      end

      nil
    end

    def DelHttpAccess(id_item)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@http_accesses))
        SetModified()
        @http_accesses = Builtins.remove(@http_accesses, id_item)
      end

      nil
    end

    def MoveHttpAccess(id_from, id_to)
      if Ops.greater_or_equal(id_from, 0) &&
          Ops.less_than(id_from, Builtins.size(@http_accesses)) &&
          Ops.greater_or_equal(id_to, 0) &&
          Ops.less_than(id_to, Builtins.size(@http_accesses)) &&
          id_from != id_to
        SetModified()
        tmp = Ops.get(@http_accesses, id_from, {})
        Ops.set(@http_accesses, id_from, Ops.get(@http_accesses, id_to, {}))
        Ops.set(@http_accesses, id_to, tmp)
      end

      nil
    end
    #****** HTTP_ACCESS END *****

    #****** SETTINGS ****
    def GetSettings
      deep_copy(@settings)
    end

    def GetSetting(name)
      Ops.get_list(@settings, name, [])
    end

    def SetSetting(name, value)
      value = deep_copy(value)
      tmp = deep_copy(value)

      if tmp != Ops.get_list(@settings, name, [])
        SetModified()
        Ops.set(@settings, name, value)
      end

      nil
    end

    #****** SETTINGS END ****

    #*** REFRESH PATTERN ***
    def GetRefreshPatterns
      deep_copy(@refresh_patterns)
    end

    def GetRefreshPattern(id_item)
      Ops.get(@refresh_patterns, id_item, {})
    end

    def AddRefreshPattern(regexp, min, percent, max, case_sensitive)
      SetModified()
      @refresh_patterns = Builtins.add(
        @refresh_patterns,
        {
          "regexp"         => regexp,
          "min"            => min,
          "percent"        => percent,
          "max"            => max,
          "case_sensitive" => case_sensitive
        }
      )

      nil
    end

    def ModifyRefreshPattern(id_item, regexp, min, percent, max, case_sensitive)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@refresh_patterns))
        tmp = {
          "regexp"         => regexp,
          "min"            => min,
          "percent"        => percent,
          "max"            => max,
          "case_sensitive" => case_sensitive
        }
        if tmp != Ops.get(@refresh_patterns, id_item, {})
          SetModified()
          Ops.set(@refresh_patterns, id_item, tmp)
        end
      end

      nil
    end

    def DelRefreshPattern(id_item)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@refresh_patterns))
        SetModified()
        @refresh_patterns = Builtins.remove(@refresh_patterns, id_item)
      end

      nil
    end

    def MoveRefreshPattern(id_from, id_to)
      if Ops.greater_or_equal(id_from, 0) &&
          Ops.less_than(id_from, Builtins.size(@refresh_patterns)) &&
          Ops.greater_or_equal(id_to, 0) &&
          Ops.less_than(id_to, Builtins.size(@refresh_patterns)) &&
          id_from != id_to
        SetModified()
        tmp = Ops.get(@refresh_patterns, id_from, {})
        Ops.set(
          @refresh_patterns,
          id_from,
          Ops.get(@refresh_patterns, id_to, {})
        )
        Ops.set(@refresh_patterns, id_to, tmp)
      end

      nil
    end
    #*** REFRESH PATTERN END ***

    #*** HTTP PORT ****
    # Returns only list of configured ports (no hosts and so on)
    def GetHttpPortsOnly
      ret = []
      @http_ports.each do |value|
        if Ops.greater_than(Builtins.size(Ops.get_string(value, "port", "")), 0)
          ret = Builtins.add(ret, Ops.get_string(value, "port", ""))
        end
      end
      deep_copy(ret)
    end

    def GetHttpPorts
      deep_copy(@http_ports)
    end

    def GetHttpPort(id_item)
      Ops.get(@http_ports, id_item, {})
    end

    def AddHttpPort(host, port, transparent)
      SetModified()
      @http_ports = Builtins.add(
        @http_ports,
        { "host" => host, "port" => port, "transparent" => transparent }
      )

      nil
    end

    def ModifyHttpPort(id_item, host, port, transparent)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@http_ports))
        tmp = { "host" => host, "port" => port, "transparent" => transparent }
        if tmp != Ops.get(@http_ports, id_item, {})
          SetModified()
          Ops.set(@http_ports, id_item, tmp)
        end
      end

      nil
    end

    def DelHttpPort(id_item)
      if Ops.greater_or_equal(id_item, 0) &&
          Ops.less_than(id_item, Builtins.size(@http_ports))
        SetModified()
        @http_ports = Builtins.remove(@http_ports, id_item)
      end

      nil
    end
    #*** HTTP PORT END ****



    #*******************  READ  *********************


    # Read setting of parameter http_port.
    #      http_port [hostname:]port [transparent]
    #
    # return true on success
    def readHttpPorts
      ok = true
      tmp = []
      tmp_http_port = {}

      @http_ports = []
      Builtins.foreach(
        Convert.convert(
          SCR.Read(Builtins.add(@squid_path, "http_port")),
          :from => "any",
          :to   => "list <list <string>>"
        )
      ) do |value|
        tmp_http_port = {}
        tmp = []
        #can parse only 'http_port hostname:port [transparent]'
        if Ops.less_than(Builtins.size(value), 1) ||
            Ops.greater_than(Builtins.size(value), 2)
          ok = false
          next false
        end
        # hostname and port
        tmp = split(Ops.get(value, 0, ""), ":")
        Builtins.y2debug("readHttpPorts - tmp: %1", tmp)
        if Builtins.size(tmp) == 1
          Ops.set(tmp_http_port, "host", "")
          Ops.set(tmp_http_port, "port", Ops.get_string(tmp, 0, ""))
        else
          Ops.set(tmp_http_port, "host", Ops.get_string(tmp, 0, ""))
          Ops.set(tmp_http_port, "port", Ops.get_string(tmp, 1, ""))
        end
        #transparent option
        if Builtins.size(value) == 2 && Ops.get(value, 1, "") == "transparent"
          Ops.set(tmp_http_port, "transparent", true)
        end
        @http_ports = Builtins.add(@http_ports, tmp_http_port)
      end

      ok
    end

    # Read setting of parameter http_access.
    #      http_access allow acl1 !acl2 ...
    #
    # return true on success
    def readHttpAccesses
      ok = true
      tmp_http_access = {}

      @http_accesses = []
      Builtins.foreach(
        Convert.convert(
          SCR.Read(Builtins.add(@squid_path, "http_access")),
          :from => "any",
          :to   => "list <list <string>>"
        )
      ) do |value|
        tmp_http_access = {}
        if Ops.get(value, 0, "") != "allow" && Ops.get(value, 0, "") != "deny"
          ok = false
          next false
        end
        Ops.set(
          tmp_http_access,
          "allow",
          Ops.get(value, 0, "") == "allow" ? true : false
        )
        Ops.set(tmp_http_access, "acl", Builtins.remove(value, 0))
        @http_accesses = Builtins.add(@http_accesses, tmp_http_access)
      end

      ok
    end

    # Read setting of parameter refresh_pattern.
    #      refresh_pattern [-i] regexp min percent max [options (ignored)]
    #
    # return true on success
    def readRefreshPatterns
      ok = true
      tmp_refresh_pattern = {}

      @refresh_patterns = []
      Builtins.foreach(
        Convert.convert(
          SCR.Read(Builtins.add(@squid_path, "refresh_pattern")),
          :from => "any",
          :to   => "list <list <string>>"
        )
      ) do |value|
        tmp_refresh_pattern = {}
        #case-insesitive
        if Ops.get(value, 0, "") == "-i"
          Ops.set(tmp_refresh_pattern, "case_sensitive", false)
          value = Builtins.remove(value, 0)
        else
          Ops.set(tmp_refresh_pattern, "case_sensitive", true)
        end
        if Ops.less_than(Builtins.size(value), 4)
          ok = false
          next false
        end
        Ops.set(tmp_refresh_pattern, "regexp", Ops.get(value, 0, ""))
        Ops.set(tmp_refresh_pattern, "min", Ops.get(value, 1, ""))
        Ops.set(
          tmp_refresh_pattern,
          "percent",
          Builtins.deletechars(Ops.get(value, 2, ""), "%")
        )
        Ops.set(tmp_refresh_pattern, "max", Ops.get(value, 3, ""))
        @refresh_patterns = Builtins.add(@refresh_patterns, tmp_refresh_pattern)
      end

      ok
    end

    # Read setting of parameter acl.
    #      acl aclname acltype string1 string2 ...
    #
    # return true on success
    def readACLs
      ok = true
      tmp_acl = {}

      #list of types which contains regular expression
      regexps = [
        "srcdom_regex",
        "dstdom_regex",
        "url_regex",
        "urlpath_regex",
        "browser"
      ]

      @acls = []
      Builtins.foreach(
        Convert.convert(
          SCR.Read(Builtins.add(@squid_path, "acl")),
          :from => "any",
          :to   => "list <list <string>>"
        )
      ) do |value|
        tmp_acl = {}
        if Ops.less_than(Builtins.size(value), 3)
          ok = false
          next false
        end
        Ops.set(tmp_acl, "name", Ops.get(value, 0, ""))
        Ops.set(tmp_acl, "type", Ops.get(value, 1, ""))
        Ops.set(
          tmp_acl,
          "options",
          Builtins.remove(Builtins.remove(value, 0), 0)
        )
        # Special settings:
        # concat list of regular expressions into one option
        if Builtins.contains(regexps, Ops.get_string(tmp_acl, "type", ""))
          if Ops.get(Ops.get_list(tmp_acl, "options", []), 0, "") == "-i"
            Ops.set(
              tmp_acl,
              "options",
              [
                "-i",
                Builtins.mergestring(
                  Convert.convert(
                    Builtins.remove(Ops.get_list(tmp_acl, "options", []), 0),
                    :from => "list",
                    :to   => "list <string>"
                  ),
                  " "
                )
              ]
            )
          else
            Ops.set(
              tmp_acl,
              "options",
              [Builtins.mergestring(Ops.get_list(tmp_acl, "options", []), " ")]
            )
          end
        #format: acl aclname header_name [-i] list of regexps
        elsif Ops.get_string(tmp_acl, "type", "") == "req_header" ||
            Ops.get_string(tmp_acl, "type", "") == "rep_header"
          if Ops.get(Ops.get_list(tmp_acl, "options", []), 1, "") == "-i"
            Ops.set(
              tmp_acl,
              "options",
              [
                Ops.get(Ops.get_list(tmp_acl, "options", []), 0, ""),
                "-i",
                Builtins.mergestring(
                  Convert.convert(
                    Builtins.remove(
                      Builtins.remove(Ops.get_list(tmp_acl, "options", []), 0),
                      0
                    ),
                    :from => "list",
                    :to   => "list <string>"
                  ),
                  " "
                )
              ]
            )
          else
            Ops.set(
              tmp_acl,
              "options",
              [
                Ops.get(Ops.get_list(tmp_acl, "options", []), 0, ""),
                Builtins.mergestring(
                  Convert.convert(
                    Builtins.remove(Ops.get_list(tmp_acl, "options", []), 0),
                    :from => "list",
                    :to   => "list <string>"
                  ),
                  " "
                )
              ]
            )
          end
        end
        @acls = Builtins.add(@acls, tmp_acl)
      end

      verifyACLs

      ok
    end

    # Read rest of setting.
    # return true on success
    def readRestSetting
      ok = true
      tmp = []

      @settings = {}
      Builtins.foreach(@parameters) do |key, value|
        tmp = Convert.convert(
          SCR.Read(Builtins.add(@squid_path, key)),
          :from => "any",
          :to   => "list <list <string>>"
        )
        #tmp = split(tmp[0]:"", " \t");
        tmp = Ops.get_list(tmp, 0, [])
        if Ops.greater_than(Builtins.size(tmp), 0)
          Ops.set(@settings, key, tmp)
        else
          Ops.set(@settings, key, value)
        end
      end

      #special modification
      Ops.set(
        @settings,
        "cache_replacement_policy",
        [
          Builtins.mergestring(
            Ops.get_list(@settings, "cache_replacement_policy", []),
            " "
          )
        ]
      )
      Ops.set(
        @settings,
        "memory_replacement_policy",
        [
          Builtins.mergestring(
            Ops.get_list(@settings, "memory_replacement_policy", []),
            " "
          )
        ]
      )
      Ops.set(
        @settings,
        "connect_timeout",
        [
          Ops.get(Ops.get_list(@settings, "connect_timeout", []), 0, ""),
          repairTimeoutPeriodUnits(
            Ops.get(Ops.get_list(@settings, "connect_timeout", []), 1, "")
          )
        ]
      )
      Ops.set(
        @settings,
        "client_lifetime",
        [
          Ops.get(Ops.get_list(@settings, "client_lifetime", []), 0, ""),
          repairTimeoutPeriodUnits(
            Ops.get(Ops.get_list(@settings, "client_lifetime", []), 1, "")
          )
        ]
      )

      ok
    end

    def readServiceStatus
      @service_enabled_on_startup = Service.Enabled("squid")
      true
    end

    def readAllSettings
      ok = true

      ok = false if !readHttpPorts
      Progress.NextStage

      ok = false if !readRefreshPatterns
      Progress.NextStage

      ok = false if !readACLs
      Progress.NextStage

      ok = false if !readHttpAccesses
      Progress.NextStage

      ok = false if !readRestSetting
      Progress.NextStage

      ok
    end

    # Read all squid settings
    # @return true on success
    def Read
      ok = true

      Progress.New(
        _("Initializing Squid Configuration"),
        " ",
        7,
        [
          _("Read HTTP Ports from Config File."),
          _("Read Refresh Patterns from Config File."),
          _("Read ACL Groups from Config File."),
          _("Read Access Control Table from Config File."),
          _("Read Other Settings."),
          _("Read Service Status."),
          _("Read Firewall Settings.")
        ],
        [
          _("Reading HTTP Ports ..."),
          _("Reading Refresh Patterns ..."),
          _("Reading ACL Groups ..."),
          _("Reading Access Control Table ..."),
          _("Reading Other Settings ..."),
          _("Reading Service Status ..."),
          _("Reading Firewall Settings ...")
        ],
        ""
      )

      return false if Abort()
      Progress.NextStage

      if !readAllSettings
        ok = false
        Report.Error(_("Cannot read configuration file."))
      end

      if !readServiceStatus
        ok = false
        Report.Error(_("Cannot read service status."))
      end
      Progress.NextStage

      Progress.set(false)
      if !firewalld.read
        # bnc#808722: yast2 squid fail if SuSEfirewall in not installed
        # other or no firewall can be installed
        Builtins.y2warning("Cannot read firewall settings.")
      end
      Progress.set(true)
      Progress.NextStage

      Builtins.y2milestone("================ Setting ======================")
      Builtins.y2debug("Squid::Read - http_ports: %1", @http_ports)
      Builtins.y2debug("Squid::Read - http_accesses: %1", @http_accesses)
      Builtins.y2debug("Squid::Read - acls: %1", @acls)
      Builtins.y2debug("Squid::Read - refresh_patterns: %1", @refresh_patterns)
      Builtins.y2debug("Squid::Read - settings: %1", @settings)
      Builtins.y2debug("Squid::Read - enabled: %1", @service_enabled_on_startup)
      Builtins.y2milestone("================ Setting END ==================")

      ok
    end
    #*******************  READ END  *****************



    #*******************  WRITE  ********************


    def writeHttpPorts
      ok = true
      scr = []
      tmp = []

      Builtins.foreach(@http_ports) do |value|
        tmp = []
        if Ops.greater_than(Builtins.size(Ops.get_string(value, "host", "")), 0)
          Ops.set(
            tmp,
            0,
            Ops.add(
              Ops.add(Ops.get_string(value, "host", ""), ":"),
              Ops.get_string(value, "port", "")
            )
          )
        else
          Ops.set(tmp, 0, Ops.get_string(value, "port", ""))
        end
        if Ops.get_boolean(value, "transparent", false)
          Ops.set(tmp, 1, "transparent")
        end
        scr = Builtins.add(scr, tmp)
      end

      Builtins.y2debug("Squid::Write - http_port: %1", scr)
      ok = false if !SCR.Write(Builtins.add(@squid_path, "http_port"), scr)

      ok
    end

    def writeACLs
      ok = true
      scr = []
      tmp = []

      Builtins.foreach(@acls) do |value|
        tmp = []
        Ops.set(tmp, 0, Ops.get_string(value, "name", ""))
        Ops.set(tmp, 1, Ops.get_string(value, "type", ""))
        tmp = Convert.convert(
          Builtins.merge(tmp, Ops.get_list(value, "options", [])),
          :from => "list",
          :to   => "list <string>"
        )
        scr = Builtins.add(scr, tmp)
      end

      Builtins.y2debug("Squid::Write - acl: %1", scr)
      ok = false if !SCR.Write(Builtins.add(@squid_path, "acl"), scr)

      ok
    end


    def writeHttpAccesses
      ok = true
      scr = []
      tmp = []

      Builtins.foreach(@http_accesses) do |value|
        tmp = []
        if Ops.get_boolean(value, "allow", true)
          Ops.set(tmp, 0, "allow")
        else
          Ops.set(tmp, 0, "deny")
        end
        tmp = Convert.convert(
          Builtins.merge(tmp, Ops.get_list(value, "acl", [])),
          :from => "list",
          :to   => "list <string>"
        )
        scr = Builtins.add(scr, tmp)
      end

      Builtins.y2debug("Squid::Write - http_access: %1", scr)
      ok = false if !SCR.Write(Builtins.add(@squid_path, "http_access"), scr)

      ok
    end


    def writeRefreshPatterns
      ok = true
      scr = []
      tmp = []

      Builtins.foreach(@refresh_patterns) do |value|
        tmp = []
        if !Ops.get_boolean(value, "case_sensitive", false)
          Ops.set(tmp, 0, "-i ")
        end
        tmp = Builtins.add(tmp, Ops.get_string(value, "regexp", ""))
        tmp = Builtins.add(tmp, Ops.get_string(value, "min", ""))
        tmp = Builtins.add(tmp, Ops.get_string(value, "percent", ""))
        tmp = Builtins.add(tmp, Ops.get_string(value, "max", ""))
        scr = Builtins.add(scr, tmp)
      end

      Builtins.y2debug("Squid::Write - refresh_pattern: %1", scr)
      if !SCR.Write(Builtins.add(@squid_path, "refresh_pattern"), scr)
        ok = false
      end

      ok
    end


    def writeRestSetting
      ok = true

      Builtins.foreach(@parameters) do |key, value|
        value = Ops.get_list(@settings, key, [])
        if Ops.greater_than(Builtins.size(value), 0)
          Builtins.y2debug("Squid::Write - %1: %2", key, value)
          if !SCR.Write(Builtins.add(@squid_path, key), [value])
            Builtins.y2error("Squid::Write - cannot write %1 setting", key)
            ok = false
          end
        else
          Builtins.y2debug("Squid::Write - %1: %2", key, nil)
          if !SCR.Write(Builtins.add(@squid_path, key), nil)
            Builtins.y2error("Squid::Write - cannot write %1 setting", key)
            ok = false
          end
        end
      end

      ok
    end

    def writePermissions
      cache_dir = Ops.get(Ops.get_list(@settings, "cache_dir", []), 1, "")
      ok = true

      ok = false if !setWritePremissionsToCacheDir(cache_dir)
      ok
    end

    def writeAllSettings
      ok = true

      ok = false if !writePermissions

      if !GetModified()
        Builtins.y2debug(
          "Squid::Write - no setting to write, because nothing's changed"
        )
        return ok
      end

      Builtins.y2milestone("Squid::writeAllSettings started")

      if !writeHttpPorts
        Builtins.y2error("Squid::writeAllSettings - writeHttpPorts failed")
        ok = false
      end
      if !writeACLs
        Builtins.y2error("Squid::writeAllSettings - writeACLs failed")
        ok = false
      end
      if !writeHttpAccesses
        Builtins.y2error("Squid::writeAllSettings - writeHttpAccesses failed")
        ok = false
      end
      if !writeRefreshPatterns
        Builtins.y2error(
          "Squid::writeAllSettings - writeRefreshPatterns failed"
        )
        ok = false
      end
      if !writeRestSetting
        Builtins.y2error("Squid::writeAllSettings - writeRestSetting failed")
        ok = false
      end

      if ok
        if !SCR.Write(@squid_path, nil)
          Builtins.y2error(
            "Squid::Write - cannot write settings: `Write(%1, nil)",
            @squid_path
          )
          ok = false
        end
      end

      Builtins.y2milestone("Squid::writeAllSettings finished")

      ok
    end

    def writeFirewallSettings
      if !GetModified()
        Builtins.y2debug(
          "Squid::writeFirewallSettings - no setting to write, because nothing's changed"
        )
        return true
      end

      tcp_ports = GetHttpPortsOnly()

      begin
        Y2Firewall::Firewalld::Service.modify_ports(
          name: @firewall_service_name,
          tcp_ports: GetHttpPortsOnly()
        )
      rescue Y2Firewall::Firewalld::Service::NotFound
        Builtins.y2error("Firewalld '#{@firewall_service_name}' service is not available.")
        return false
      end

      firewalld.write
    end

    # @deprecated
    # Returns true if Squid service is running.
    def IsServiceRunning
      Service.Status("squid") == 0
    end

    # @deprecated
    # Start Squid service if not running otherwise reload.
    # Returns true if squid was successfuly started
    def StartService
      ok = true
      #verify config file
      #if ((integer)SCR::Execute(.target.bash, "squid -k parse") != 0){
      #    y2error("Squid::Write - startService - 'squid -k parse' failed");
      #    return false;
      #}

      if !IsServiceRunning()
        if !Service.Start("squid")
          ok = false
          Report.Error(Message.CannotStartService("squid"))
        end
      else
        if !Service.Restart("squid")
          ok = false
          Report.Error(Message.CannotRestartService("squid"))
        end
      end

      ok
    end

    # @deprecated
    # Stop Squid service.
    # Returns true if squid was successfuly stopped
    def StopService
      ok = true

      if IsServiceRunning()
        if !Service.Stop("squid")
          ok = false
          Report.Error(Message.CannotStopService("squid"))
        end
      end
      ok
    end

    # @deprecated
    def EnableService
      Service.Enable("squid")
    end

    # @deprecated
    def DisableService
      Service.Disable("squid")
    end

    # Write all Squid settings
    #
    # @return [Boolean] true when all operations were done successfuly; false otherwise
    def Write
      result = true

      stages = [
        _("Write the settings"),
        _("Write firewall settings"),
        _("Save Service")
      ]

      steps = [
        _("Writing the settings..."),
        _("Writing firewall settings..."),
        _("Saving Service..."),
        _("Finished")
      ]

      Progress.New(_("Saving Squid Configuration"), " ", stages.count, stages, steps, "")

      return false if Abort()

      # write settings
      Progress.NextStage
      if !writeAllSettings
        Report.Error(_("Cannot write settings."))

        result = false
      end

      # write firewall settings
      Progress.NextStage
      if !writeFirewallSettings
        Report.Error(_("Cannot write firewall settings."))

        result = false
      end

      # save service status
      Progress.NextStage
      result = false unless save_status
      result = false unless start_service

      return false if Abort()

      # Progress finished
      Progress.NextStage

      return false if Abort()
      result
    end
    #*******************  WRITE END  ****************

    # Saves service status (start mode and starts/stops the service)
    #
    # @note For AutoYaST and for command line actions, it uses the old way
    # for backward compatibility. When the service is configured by using the
    # UI, it directly saves the service, see Yast2::SystemService#save.
    def save_status
      if Mode.auto || Mode.commandline
        IsServiceEnabled() ? EnableService() : DisableService()
      else
        service.save
      end
    end

    # Starts or restars the service
    #
    # @note for backward compatibility, only in AutoYaST and command line
    # actions. When the service is configured using the UI, properly action is
    # performed at the moment to save it.
    def start_service
      if !@write_only && (Mode.auto || Mode.commandline)
        StartService()
      else
        true
      end
    end

    #******************  AUTOYAST  ******************

    # Get all squid settings from the first parameter
    # (For use by autoinstallation.)
    # @param settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(sett)
      sett = deep_copy(sett)
      if sett == {} || sett == nil
        SetDefaultValues()
        SetModified()
        return true
      end
      if !Builtins.haskey(sett, "http_ports") || !Builtins.haskey(sett, "acls") ||
          !Builtins.haskey(sett, "http_accesses") ||
          !Builtins.haskey(sett, "refresh_patterns") ||
          !Builtins.haskey(sett, "settings") ||
          !Builtins.haskey(sett, "service_enabled_on_startup")
        return false
      end

      @http_ports = Ops.get_list(sett, "http_ports", [])
      @acls = Ops.get_list(sett, "acls", [])
      @http_accesses = Ops.get_list(sett, "http_accesses", [])
      @refresh_patterns = Ops.get_list(sett, "refresh_patterns", [])
      @settings = Ops.get_map(sett, "settings", {})
      @service_enabled_on_startup = Ops.get_boolean(
        sett,
        "service_enabled_on_startup",
        false
      )
      SetModified()

      true
    end

    # Dump the squid settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      {
        "http_ports"                 => @http_ports,
        "acls"                       => @acls,
        "http_accesses"              => @http_accesses,
        "refresh_patterns"           => @refresh_patterns,
        "settings"                   => @settings,
        "service_enabled_on_startup" => @service_enabled_on_startup
      }
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      summary = ""
      tmp = ""
      if !GetModified()
        summary = Summary.NotConfigured
      else
        # Header
        summary = Summary.AddHeader("", _("Squid Cache Proxy"))

        # Start daemon
        summary = Summary.AddLine(
          summary,
          _("Start daemon: ") + "<i>" +
            (@service_enabled_on_startup ? _("When booting") : _("Manually")) + "</i>"
        )

        # Http Ports
        summary = Summary.AddLine(summary, _("Configured ports:"))
        if Ops.greater_than(Builtins.size(@http_ports), 0)
          summary = Summary.OpenList(summary)
          Builtins.foreach(@http_ports) do |value|
            tmp = "<i>"
            if Ops.greater_than(
                Builtins.size(Ops.get_string(value, "host", "")),
                0
              )
              tmp = Ops.add(
                Ops.add(tmp, Ops.get_string(value, "host", "")),
                ":"
              )
            end
            tmp = Ops.add(
              Ops.add(tmp, Ops.get_string(value, "port", "")),
              Ops.get_boolean(value, "transparent", false) ?
                _(" (transparent)") :
                ""
            )
            tmp = Ops.add(tmp, "</i>")
            summary = Summary.AddListItem(summary, tmp)
          end
          summary = Summary.CloseList(summary)
        end

        #Cache directory
        summary = Summary.AddLine(
          summary,
          Ops.add(
            Ops.add(
              _("Cache directory: ") + "<i>",
              Ops.get(Ops.get_list(@settings, "cache_dir", []), 1, "")
            ),
            "</i>"
          )
        )
      end
      [summary, []]
    end

    #  * Create an overview table with all configured cards
    #  * @return table items
    #  *
    # global list Overview() {
    #     return [];
    # }

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      { "install" => ["squid"], "remove" => [] }
    end

    # Returns the service
    #
    # @return [Yast2::SystemService]
    def service
      @service ||= Yast2::SystemService.find("squid")
    end

    publish :variable => :squid_path, :type => "path", :private => true
    publish :variable => :sysconfig_file, :type => "string", :private => true
    publish :variable => :firewall_service_name, :type => "string", :private => true
    publish :function => :GetFirewallServiceName, :type => "string ()"
    publish :variable => :modified, :type => "boolean", :private => true
    publish :variable => :service_enabled_on_startup, :type => "boolean", :private => true
    publish :variable => :settings, :type => "map <string, any>", :private => true
    publish :variable => :http_ports, :type => "list <map <string, any>>", :private => true
    publish :variable => :acls, :type => "list <map <string, any>>", :private => true
    publish :variable => :http_accesses, :type => "list <map <string, any>>", :private => true
    publish :variable => :refresh_patterns, :type => "list <map <string, any>>", :private => true
    publish :variable => :parameters, :type => "map <string, list>", :private => true
    publish :variable => :write_only, :type => "boolean"
    publish :function => :split, :type => "list <string> (string, string)", :private => true
    publish :function => :NumACLs, :type => "integer (integer)"
    publish :function => :verifyACLs, :type => "void ()", :private => true
    publish :function => :repairTimeoutPeriodUnits, :type => "string (string)", :private => true
    publish :function => :setWritePremissionsToCacheDir, :type => "boolean (string)", :private => true
    publish :function => :SetDefaultValues, :type => "void ()"
    publish :function => :GetModified, :type => "boolean ()"
    publish :function => :SetModified, :type => "void ()"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :IsServiceEnabled, :type => "boolean ()"
    publish :function => :SetServiceEnabled, :type => "void (boolean)"
    publish :function => :GetACLs, :type => "list <map <string, any>> ()"
    publish :function => :GetACL, :type => "map <string, any> (integer)"
    publish :function => :GetACLType, :type => "string (integer)"
    publish :function => :GetACLTypeByName, :type => "string (string)"
    publish :function => :AddACL, :type => "void (string, string, list <string>)"
    publish :function => :ModifyACL, :type => "void (integer, string, string, list <string>)"
    publish :function => :DelACL, :type => "void (integer)"
    publish :function => :NumACLsByName, :type => "integer (string)"
    publish :function => :ACLIsUsedBy, :type => "list <string> (integer)"
    publish :function => :GetHttpAccesses, :type => "list <map <string, any>> ()"
    publish :function => :GetHttpAccess, :type => "map <string, any> (integer)"
    publish :function => :AddHttpAccess, :type => "void (boolean, list <string>)"
    publish :function => :ModifyHttpAccess, :type => "void (integer, boolean, list <string>)"
    publish :function => :DelHttpAccess, :type => "void (integer)"
    publish :function => :MoveHttpAccess, :type => "void (integer, integer)"
    publish :function => :GetSettings, :type => "map <string, any> ()"
    publish :function => :GetSetting, :type => "list <string> (string)"
    publish :function => :SetSetting, :type => "void (string, list)"
    publish :function => :GetRefreshPatterns, :type => "list <map <string, any>> ()"
    publish :function => :GetRefreshPattern, :type => "map <string, any> (integer)"
    publish :function => :AddRefreshPattern, :type => "void (string, string, string, string, boolean)"
    publish :function => :ModifyRefreshPattern, :type => "void (integer, string, string, string, string, boolean)"
    publish :function => :DelRefreshPattern, :type => "void (integer)"
    publish :function => :MoveRefreshPattern, :type => "void (integer, integer)"
    publish :function => :GetHttpPortsOnly, :type => "list <string> ()"
    publish :function => :GetHttpPorts, :type => "list <map <string, any>> ()"
    publish :function => :GetHttpPort, :type => "map <string, any> (integer)"
    publish :function => :AddHttpPort, :type => "void (string, string, boolean)"
    publish :function => :ModifyHttpPort, :type => "void (integer, string, string, boolean)"
    publish :function => :DelHttpPort, :type => "void (integer)"
    publish :function => :readHttpPorts, :type => "boolean ()", :private => true
    publish :function => :readHttpAccesses, :type => "boolean ()", :private => true
    publish :function => :readRefreshPatterns, :type => "boolean ()", :private => true
    publish :function => :readACLs, :type => "boolean ()", :private => true
    publish :function => :readRestSetting, :type => "boolean ()", :private => true
    publish :function => :readServiceStatus, :type => "boolean ()", :private => true
    publish :function => :readAllSettings, :type => "boolean ()", :private => true
    publish :function => :Read, :type => "boolean ()"
    publish :function => :writeHttpPorts, :type => "boolean ()", :private => true
    publish :function => :writeACLs, :type => "boolean ()", :private => true
    publish :function => :writeHttpAccesses, :type => "boolean ()", :private => true
    publish :function => :writeRefreshPatterns, :type => "boolean ()", :private => true
    publish :function => :writeRestSetting, :type => "boolean ()", :private => true
    publish :function => :writePermissions, :type => "boolean ()", :private => true
    publish :function => :writeAllSettings, :type => "boolean ()", :private => true
    publish :function => :writeFirewallSettings, :type => "boolean ()", :private => true
    publish :function => :IsServiceRunning, :type => "boolean ()"
    publish :function => :StartService, :type => "boolean ()"
    publish :function => :StopService, :type => "boolean ()"
    publish :function => :EnableService, :type => "boolean ()"
    publish :function => :DisableService, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"

    private

      def firewalld
        Y2Firewall::Firewalld.instance
      end
  end

  Squid = SquidClass.new
  Squid.main
end
