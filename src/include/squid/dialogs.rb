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

# File:	include/squid/dialogs.ycp
# Package:	Configuration of squid
# Summary:	Dialogs definitions
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id: dialogs.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module SquidDialogsInclude
    def initialize_squid_dialogs(include_target)
      textdomain "squid"

      Yast.import "Label"

      Yast.include include_target, "squid/helper_functions.rb"
    end

    def HttpPortsTableWidget
      VBox(
        Left(Label(_("HTTP Ports"))),
        Table(
          Id("http_port"),
          Opt(:notify),
          Header(_("Host"), _("Port"), _("Options"))
        ),
        HBox(
          PushButton(Id(:add), Label.AddButton),
          PushButton(Id(:edit), Label.EditButton),
          PushButton(Id(:del), Label.DeleteButton),
          HStretch()
        )
      )
    end

    def RefreshPatternsTableWidget
      VBox(
        Left(Label(_("Refresh Patterns"))),
        HBox(
          Table(
            Id("refresh_patterns"),
            Opt(:keepSorting, :notify),
            Header(
              _("Regular Expression"), #, _("Options")
              # table header, stands for minimum
              _("Min"),
              # table header
              _("Percent"),
              # table header, stands for maximum
              _("Max")
            )
          ),
          Top(
            VBox(
              PushButton(Id(:up), Label.UpButton),
              PushButton(Id(:down), Label.DownButton)
            )
          )
        ),
        HBox(
          PushButton(Id(:add), Label.AddButton),
          PushButton(Id(:edit), Label.EditButton),
          PushButton(Id(:del), Label.DeleteButton),
          HStretch()
        )
      )
    end

    def Cache2DialogWidget
      HBox(
        HSpacing(3),
        Frame(
          _("Cache Setting"),
          VBox(
            VWeight(
              1,
              HBox(
                IntField(Id("cache_mem"), _("C&ache Memory"), 1, 99999, 10),
                sizeUnitWidget("cache_mem_units")
              )
            ),
            VSpacing(0.4),
            VWeight(
              1,
              HBox(
                IntField(
                  Id("cache_max_object_size"),
                  _("Ma&x Object Size"),
                  0,
                  99999,
                  0
                ),
                sizeUnitWidget("cache_max_object_size_units")
              )
            ),
            VSpacing(0.4),
            VWeight(
              1,
              HBox(
                IntField(
                  Id("cache_min_object_size"),
                  _("M&in Object Size"),
                  0,
                  99999,
                  0
                ),
                sizeUnitWidget("cache_min_object_size_units")
              )
            ),
            VSpacing(0.4),
            VWeight(
              1,
              HBox(
                IntField(
                  Id("cache_swap_low"),
                  _("Swap &Low-Water Mark (percentage)"),
                  0,
                  100,
                  0
                )
              )
            ),
            VSpacing(0.4),
            VWeight(
              1,
              HBox(
                IntField(
                  Id("cache_swap_high"),
                  _("Swap &High-Water Mark (percentage)"),
                  0,
                  100,
                  0
                )
              )
            ),
            VSpacing(0.4),
            Left(
              VWeight(
                1,
                HBox(
                  ComboBox(
                    Id("cache_replacement_policy"),
                    _("&Cache Replacement Policy"),
                    [
                      Item("lru"),
                      Item("heap GDSF"),
                      Item("heap LFUDA"),
                      Item("heap LRU")
                    ]
                  )
                )
              )
            ),
            VSpacing(0.4),
            Left(
              VWeight(
                1,
                HBox(
                  ComboBox(
                    Id("memory_replacement_policy"),
                    _("&Memory Replacement Policy"),
                    [
                      Item("lru"),
                      Item("heap GDSF"),
                      Item("heap LFUDA"),
                      Item("heap LRU")
                    ]
                  )
                )
              )
            )
          )
        ),
        HSpacing(3)
      ) 
      #     `HBox(
      #         `HSpacing(3),
      #         `Frame(_("Cache Setting"),
      #             `HBox(
      #                 `HWeight(1,`VBox(
      #                     `VWeight(1, `HBox(
      #                         `IntField(`id("cache_mem"), _("C&ache Memory"), 1, 99999, 10),
      #                         sizeUnitWidget("cache_mem_units")
      #                     )),
      #                     `VSpacing(0.4),
      #                     `VWeight(1, `HBox(
      #                         `IntField(`id("cache_max_object_size"), _("Ma&x Object Size"), 0, 99999, 0),
      #                         sizeUnitWidget("cache_max_object_size_units")
      #                     )),
      #                     `VSpacing(0.4),
      #                     `VWeight(1, `HBox(
      #                         `IntField(`id("cache_swap_low"), _("Swap &Low-Water Mark (in percents)"), 0, 100, 0)
      #                     )),
      #                     `VSpacing(0.4),
      #                     `Left(`VWeight(1, `HBox(
      #                         `ComboBox(`id("cache_replacement_policy"),
      #                                   _("&Cache Replacement Policy"),
      #                                   [`item("lru"), `item("heap GDSF"), `item("heap LFUDA"), `item("heap LRU")])
      #                     )))
      #                 )),
      #                 `HSpacing(3),
      #                 `HWeight(1,`VBox(
      #                     `VWeight(1, `HBox(`Empty())),
      #                     `VSpacing(0.4),
      #                     `VWeight(1, `HBox(
      #                         `IntField(`id("cache_min_object_size"), _("M&in Object Size"), 0, 99999, 0),
      #                         sizeUnitWidget("cache_min_object_size_units")
      #                     )),
      #                     `VSpacing(0.4),
      #                     `VWeight(1, `HBox(
      #                         `IntField(`id("cache_swap_high"), _("Swap &High-Water Mark (in percents)"), 0, 100, 0)
      #                     )),
      #                     `VSpacing(0.4),
      #                     `Left(`VWeight(1, `HBox(
      #                         `ComboBox(`id("memory_replacement_policy"),
      #                                   _("&Memory Replacement Policy"),
      #                                   [`item("lru"), `item("heap GDSF"), `item("heap LFUDA"), `item("heap LRU")])
      #                     )))
      #                 ))
      #             )
      #         ),
      #         `HSpacing(3)
      #     );
    end

    def CacheDirectoryDialog
      HBox(
        HSpacing(3),
        Frame(
          _("Cache Directory"),
          VBox(
            VSquash(
              HBox(
                TextEntry(Id("cache_dir"), _("&Directory Name"), ""),
                Bottom(PushButton(Id(:browse_cache_dir), Label.BrowseButton))
              )
            ),
            VSpacing(0.4),
            IntField(Id("mbytes"), _("&Size (in MB)"), 1, 99999, 1),
            VSpacing(0.4),
            IntField(Id("l1dirs"), _("L&evel 1 Directories"), 1, 99999, 1),
            VSpacing(0.4),
            IntField(Id("l2dirs"), _("Le&vel 2 Directories"), 1, 99999, 1)
          )
        ),
        HSpacing(3)
      )
    end



    def ACLGroupsTableWidget
      VBox(
        Left(Label(_("ACL Groups"))),
        Table(
          Id("acl"),
          Opt(:notify),
          Header(_("Name"), _("Type"), _("Description"))
        ),
        HBox(
          PushButton(Id(:add_acl), Label.AddButton),
          PushButton(Id(:edit_acl), Label.EditButton),
          PushButton(Id(:del_acl), Label.DeleteButton),
          HStretch()
        )
      )
    end

    def HttpAccessTableWidget
      VBox(
        Left(Label(_("Access Control"))),
        HBox(
          Table(
            Id("http_access"),
            Opt(:keepSorting, :notify),
            Header(_("Allow/Deny"), _("ACL Groups"))
          ),
          HSquash(
            Top(
              VBox(
                HWeight(1, PushButton(Id(:up_http_access), Label.UpButton)),
                HWeight(1, PushButton(Id(:down_http_access), Label.DownButton))
              )
            )
          )
        ),
        HBox(
          PushButton(Id(:add_http_access), Label.AddButton),
          PushButton(Id(:edit_http_access), Label.EditButton),
          PushButton(Id(:del_http_access), Label.DeleteButton),
          HStretch()
        )
      )
    end

    def LoggingFrameWidget
      Frame(
        _("Logging"),
        VBox(
          VSquash(
            HBox(
              TextEntry(Id("access_log"), _("&Access Log"), ""),
              Bottom(PushButton(Id(:access_log_browse), Label.BrowseButton))
            )
          ),
          VSquash(
            HBox(
              TextEntry(Id("cache_log"), _("&Cache Log"), ""),
              Bottom(PushButton(Id(:cache_log_browse), Label.BrowseButton))
            )
          ),
          VSquash(
            HBox(
              TextEntry(Id("cache_store_log"), _("Cache &Store Log"), ""),
              Bottom(
                PushButton(Id(:cache_store_log_browse), Label.BrowseButton)
              )
            )
          )
        )
      )
    end

    def TimeoutsFrameWidget
      Frame(
        _("Timeouts"),
        VBox(
          HBox(
            IntField(
              Id("connect_timeout"),
              _("Connection &Timeout"),
              0,
              99999,
              0
            ),
            timeUnitWidget("connect_timeout_units")
          ),
          HBox(
            IntField(Id("client_lifetime"), _("Client &Lifetime"), 0, 99999, 0),
            timeUnitWidget("client_lifetime_units")
          )
        )
      )
    end


    def MiscellaneousFrameWidget
      HVCenter(
        Frame(
          _("Miscellaneous Setting"),
          VBox(
            ComboBox(Id("error_language"), _("&Language of error messages"), []),
            VSpacing(),
            TextEntry(Id("cache_mgr"), _("&Administrator's email"), ""),
            VSpacing(),
            Left(CheckBox(Id("ftp_passive"), _("&Use FTP Passive Mode")))
          )
        )
      )
    end
  end
end
