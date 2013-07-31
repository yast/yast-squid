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

# File:	modules/SquidErrorMessages.ycp
# Package:	Configuration of squid
# Summary: Handle list of paths to direcotories with error messages
#          in different languages.
# Authors:	Daniel Fiser <dfiser@suse.cz>
#
# $Id$
#
require "yast"

module Yast
  class SquidErrorMessagesClass < Module
    def main
      textdomain "squid"

      Yast.import "FileUtils"


      # format:
      #      $[ "language" : "path_to_directory",
      #         ....
      #       ]
      @err = {}

      # Directory where is located directories with messages in various languages.
      @err_msg_dir = "/usr/share/squid/errors"

      @trans_map = {
        # language name - combo box entry
        "Armenian"            => _("Armenian"),
        # language name - combo box entry
        "Catalan"             => _("Catalan"),
        # language name - combo box entry
        "Dutch"               => _("Dutch"),
        # language name - combo box entry
        "Finnish"             => _("Finnish"),
        # language name - combo box entry
        "Greek"               => _("Greek"),
        # language name - combo box entry
        "Italian"             => _("Italian"),
        # language name - combo box entry
        "Lithuanian"          => _(
          "Lithuanian"
        ),
        # language name - combo box entry
        "Romanian"            => _("Romanian"),
        # language name - combo box entry
        "Serbian"             => _("Serbian"),
        # language name - combo box entry
        "Spanish"             => _("Spanish"),
        # language name - combo box entry
        "Turkish"             => _("Turkish"),
        # language name - combo box entry; don't translate the encoding suffix
        "Ukrainian-1251"      => _(
          "Ukrainian-1251"
        ),
        # language name - combo box entry
        "Azerbaijani"         => _(
          "Azerbaijani"
        ),
        # language name - combo box entry
        "Czech"               => _("Czech"),
        # language name - combo box entry
        "English"             => _("English"),
        # language name - combo box entry
        "French"              => _("French"),
        # language name - combo box entry
        "Hebrew"              => _("Hebrew"),
        # language name - combo box entry
        "Japanese"            => _("Japanese"),
        # language name - combo box entry
        "Polish"              => _("Polish"),
        # language name - combo box entry; don't translate the encoding suffix
        "Russian-koi8-r"      => _(
          "Russian-koi8-r"
        ),
        # language name - combo box entry
        "Simplify Chinese"    => _(
          "Simplified Chinese"
        ),
        # language name - combo box entry
        "Swedish"             => _("Swedish"),
        # language name - combo box entry; don't translate the encoding suffix
        "Ukrainian-koi8-u"    => _(
          "Ukrainian-koi8-u"
        ),
        # language name - combo box entry
        "Bulgarian"           => _(
          "Bulgarian"
        ),
        # language name - combo box entry
        "Danish"              => _("Danish"),
        # language name - combo box entry
        "Estonian"            => _("Estonian"),
        # language name - combo box entry
        "German"              => _("German"),
        # language name - combo box entry
        "Hungarian"           => _(
          "Hungarian"
        ),
        # language name - combo box entry
        "Korean"              => _("Korean"),
        # language name - combo box entry
        "Portuguese"          => _(
          "Portuguese"
        ),
        # language name - combo box entry; don't translate the encoding suffix
        "Russian-1251"        => _(
          "Russian-1251"
        ),
        # language name - combo box entry
        "Slovak"              => _("Slovak"),
        # language name - combo box entry
        "Traditional Chinese" => _(
          "Traditional Chinese"
        ),
        # language name - combo box entry; don't translate the encoding suffix
        "Ukrainian-utf8"      => _(
          "Ukrainian-utf8"
        )
      }
    end

    def read
      #if err uninitialized else do nothing
      if Builtins.size(@err) == 0
        @err = {}
        dir = ""
        Builtins.foreach(
          Convert.convert(
            SCR.Read(path(".target.dir"), @err_msg_dir),
            :from => "any",
            :to   => "list <string>"
          )
        ) do |value|
          if FileUtils.IsDirectory(Ops.add(Ops.add(@err_msg_dir, "/"), value))
            dir = Builtins.mergestring(Builtins.splitstring(value, "_"), " ")
            if Ops.greater_than(Builtins.size(dir), 0)
              Ops.set(@err, dir, Ops.add(Ops.add(@err_msg_dir, "/"), value))
            end
          end
        end

        Builtins.y2debug("SquidErrorMessages::read() - err: %1", @err)
      end

      nil
    end

    # Returns list of all available languages
    def GetLanguages
      read

      ret = []
      Builtins.foreach(@err) { |key, value| ret = Builtins.add(ret, key) }
      deep_copy(ret)
    end

    # Returns list of all available languages in form of items of ComboBox.
    def GetLanguagesToComboBox
      read

      ret = []
      Builtins.foreach(GetLanguages()) do |language|
        ret = Builtins.add(
          ret,
          Item(Id(language), Ops.get(@trans_map, language, language))
        )
      end
      deep_copy(ret)
    end


    # Returns path to directory containing error messages in given language.
    def GetPath(language)
      read

      Ops.get(@err, language, "")
    end

    # Inverse function to GetPath.
    # Returns languge which has path pth to directory containing error messages.
    def GetLanguageFromPath(pth)
      read

      ret = nil
      Builtins.foreach(@err) do |key, value|
        if value == pth
          ret = key
          raise Break
        end
      end

      ret
    end

    publish :variable => :err, :type => "map <string, string>", :private => true
    publish :variable => :err_msg_dir, :type => "string", :private => true
    publish :function => :read, :type => "void ()", :private => true
    publish :function => :GetLanguages, :type => "list <string> ()"
    publish :variable => :trans_map, :type => "map <string, string>", :private => true
    publish :function => :GetLanguagesToComboBox, :type => "list <term> ()"
    publish :function => :GetPath, :type => "string (string)"
    publish :function => :GetLanguageFromPath, :type => "string (string)"
  end

  SquidErrorMessages = SquidErrorMessagesClass.new
  SquidErrorMessages.main
end
