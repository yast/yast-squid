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

# File:	include/squid/helps.ycp
# Package:	Configuration of squid * Summary:	Help texts of all the dialogs except AddEditACLDialog.  * Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: helps.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module SquidHelpsInclude
    def initialize_squid_helps(_include_target)
      textdomain "squid"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"            => _(
          "<p><b><big>Initializing Squid Configuration</big></b><br>\n</p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"           => _(
          "<p><b><big>Saving Squid Configuration</big></b><br>\n</p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" \
              "Abort the save procedure by pressing <b>Abort</b>.\n" \
              "An additional dialog informs whether it is safe to do so.\n" \
              "</p>\n"
          ),
        # Summary dialog help
        "summary"         => _(
          "<p><b><big>Squid Configuration</big></b><br>\nConfigure Squid here.<br></p>\n"
        ),
        # Ovreview dialog help
        "overview"        => _(
          "<p><b><big>Squid Configuration Overview</big></b><br>\n" \
            "Obtain an overview of installed squids and\n" \
            "edit their configurations if necessary.<br></p>\n"
        ),
        # Http Ports Dialog
        "http_ports"      => _(
          "<p>Define all ports where Squid will\nlisten for clients' http requests.</p>\n"
        ) +
          _(
            "<p><b>Host</b> can contain a hostname or IP address\nor remain empty.</p>\n"
          ),
        # Cache Dialog
        "cache"           => _(
          "<p><b>Refresh Patterns</b> define how Squid treats the objects in the cache.</p>\n"
        ) +
          _(
            "<p>The refresh patterns are checked in the order listed here.\nThe first matching entry is used.</p>\n"
          ) +
          _(
            "<p><b>Min</b> determines how long (in minutes) an object should be\nconsidered fresh if no explicit expiry time is given.\n"
          ) +
          _(
            "<p><b>Percent</b> is the percentage of the object's age (time since last\n" \
              "modification). An object without explicit expiry time will be\n" \
              "considered fresh.</p>\n"
          ) +
          _(
            "<p><b>Max</b> is the upper limit of how long objects without an explicit\nexpiry time will be considered fresh.</p>\n"
          ),
        # Cache 2 Dialog
        "cache2"          => _(
          "<p><b>Cache memory</b> defines the ideal amount of memory to be used for objects.</p>"
        ) +
          _(
            "<p><b>Max Object Size</b> defines the maximum size for objects to be stored\non the disk. Objects larger than this size will not be saved on disk.</p>\n"
          ) +
          _(
            "<p><b>Min Object Size</b> specifies the minimum size for objects. Smaller \nobjects will not be saved to the disk.</p>\n"
          ) +
          _(
            "<p>Replacement begins when the swap (disk) usage is above the\n" \
              "<b>Swap Low-Water Mark</b> and attempts to maintain utilization near the\n" \
              "<b>Swap Low-Water Mark</b>. As swap utilization gets close to\n" \
              "<b>Swap High-Water Mark</b>, object eviction becomes more aggressive.\n" \
              "If utilization is close to the <b>Swap Low-Water Mark</b>, less replacement\n" \
              "is done each time.\n"
          ) +
          _(
            "<p><b>Cache Replacement Policy</b> determines which objects are to be replaced\n" \
              "when disk space is needed.\n" \
              "<b>Memory Replacement Policy</b> specifies the policy for object replacement in\n" \
              "memory when space for new objects is not available.\n" \
              "Policies could be:\n" \
              "<table>\n" \
              "    <tr>\n" \
              "      <td>lru</td>\n" \
              "      <td>least recently used</td>\n" \
              "    </tr>\n" \
              "    <tr>\n" \
              "      <td>heap GDSF</td>\n" \
              "      <td>Greedy-Dual Size Frequency</td>\n" \
              "    </tr>\n" \
              "    <tr>\n" \
              "      <td>heap LFUDA</td>\n" \
              "      <td>Least Frequently Used with Dynamic Aging</td>\n" \
              "    <tr>\n" \
              "    <tr>\n" \
              "      <td>heap LRU</td>\n" \
              "      <td>lru policy implemented using a heap</td>\n" \
              "    </tr>\n" \
              "</table>\n" \
              "</p>"
          ),
        # Cache Directory
        "cache_directory" => _(
          "<p><b>Directory Name</b> defines a top-level directory where cache swap files will be stored.</p>"
        ) +
          _(
            "<p><b>Size</b> defines the amount of disk space (in MB) to use under this directory.</p>"
          ) +
          _(
            "<p><b>Level 1 Directories</b> defines a number of first-level subdirectories, \nwhich will be created under the <b>Directory Name</b> directory.</p>\n"
          ) +
          _(
            "<p><b>Level 2 Directories</b> defines a number of second-level subdirectories,\nwhich will be created under each first-level directory.</p>\n"
          ),
        # ACL Groups
        "acl_groups"      => _(
          "<p>Access to the Squid server can be controlled via <b>ACL Groups</b>.</p>"
        ) +
          _(
            "<p><b>ACL Group</b> has various types and the description of ACL Group depends\non the particular type.</p>\n"
          ),
        "http_access"     => _(
          "<p>In the <b>Access Control</b> table, access can be denied or allowed to ACL Groups.\n" \
            "If there are more ACL Groups in one line, it means that access will be allowed\n" \
            "or denied to members who belong to all ACL Groups at the same time.</p>\n"
        ) +
          _(
            "<p>The <b>Access Control</b> table is checked in the order listed here.\nThe first matching entry is used.</p>\n"
          ),
        # Logging and Timeouts Dialog
        "logging"         => _(
          "<p><b>Access Log</b> defines the file in which client activities are logged.</p>"
        ) +
          _(
            "<p><b>Cache Log</b> defines the file in which general information about your\ncache's behavior is logged.</p>\n"
          ) +
          _(
            "<p><b>Cache Store Log</b> defines the location of the transaction log of all\n" \
              "objects that are stored in the object store, as well as the time when an object\n" \
              "gets deleted. This option can be left empty.</p>\n"
          ) +
          _(
            "<p>With <b>Emulate httpd Log</b> specify that Squid writes its\n<b>Access Log</b> in HTTPD common log file format.</p>\n"
          ),
        "timeouts"        => _(
          "<p><b>Connection Timeout</b> is an option to force Squid to close\nconnections after a specified time.</p>"
        ) +
          _(
            "<p><b>Client Lifetime</b> defines the maximum amount of time that a client\n(browser) is allowed to remain connected to the cache process.</p>"
          ),
        # Miscellaneous Dialog
        "miscellaneous"   => _(
          "<p><b>Administrator's email</b> is the address which will be added to any\nerror pages that are displayed to clients. Defaults to webmaster.</p>\n"
        )
      }

      # EOF
    end
  end
end
