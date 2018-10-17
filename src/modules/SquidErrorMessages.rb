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

      # squid use ISO 639-1 encoding for languages
      # TODO refactor it to generaly available
      @trans_map = {
        # TRANSLATORS: language name - combo box entry
        "af"      => _("Afrikaans"),
        "ar"      => _("Arabic"),
        "hy"      => _("Armenian"),
        "az"      => _("Azerbaijani"),
        "bg"      => _("Bulgarian"),
        "ca"      => _("Catalan"),
        "cs"      => _("Czech"),
        "da"      => _("Danish"),
        "de"      => _("German"),
        "el"      => _("Greek"),
        "en"      => _("English"),
        "es"      => _("Spanish"),
        "et"      => _("Estonian"),
        "fa"      => _("Persian"),
        "fi"      => _("Finnish"),
        "fr"      => _("French"),
        "he"      => _("Hebrew"),
        "hu"      => _("Hungarian"),
        "id"      => _("Indonesian"),
        "it"      => _("Italian"),
        "ja"      => _("Japanese"),
        "ko"      => _("Korean"),
        "lv"      => _("Latvian"),
        "lt"      => _("Lithuanian"),
        "ms"      => _("Malay"),
        "nl"      => _("Dutch"),
        "oc"      => _("Occitan"),
        "pl"      => _("Polish"),
        "pt"      => _("Portuguese"),
        "pt-br"   => _("Brazilian Portuguese"),
        "ro"      => _("Romanian"),
        "ru"      => _("Russian"),
        "sk"      => _("Slovak"),
        "sl"      => _("Slovenian"),
        "sr-cyrl" => _("Serbian Cyrillic"),
        "sr-latn" => _("Serbian Latin"),
        "sv"      => _("Swedish"),
        "th"      => _("Thai"),
        "tr"      => _("Turkish"),
        "uk"      => _("Ukrainian"),
        "uz"      => _("Uzbek"),
        "vi"      => _("Vietnamese"),
        "zh-cn"   => _("Simplified Chinese"),
        "zh-tw"   => _("Traditional Chinese")
      }
    end

    def read
      # if err uninitialized else do nothing
      if Builtins.size(@err) == 0
        @err = {}
        dir = ""
        Builtins.foreach(
          Convert.convert(
            SCR.Read(path(".target.dir"), @err_msg_dir),
            from: "any",
            to:   "list <string>"
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
      Builtins.foreach(@err) { |key, _value| ret = Builtins.add(ret, key) }
      deep_copy(ret)
    end

    # Returns list of all available languages in form of items of ComboBox.
    def GetLanguagesToComboBox
      read

      GetLanguages().map do |language|
        Item(Id(language), @trans_map[language] || language)
      end
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

    publish variable: :err, type: "map <string, string>", private: true
    publish variable: :err_msg_dir, type: "string", private: true
    publish function: :read, type: "void ()", private: true
    publish function: :GetLanguages, type: "list <string> ()"
    publish variable: :trans_map, type: "map <string, string>", private: true
    publish function: :GetLanguagesToComboBox, type: "list <term> ()"
    publish function: :GetPath, type: "string (string)"
    publish function: :GetLanguageFromPath, type: "string (string)"
  end

  SquidErrorMessages = SquidErrorMessagesClass.new
  SquidErrorMessages.main
end
