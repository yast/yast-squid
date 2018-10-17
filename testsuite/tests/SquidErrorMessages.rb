# encoding: utf-8

module Yast
  class SquidErrorMessagesClient < Client
    def main
      # testedfiles: SquidErrorMessages.ycp

      @read = [
        {
          "target" => {
            "dir" => [
              "en",
              "a_file",
              "ru",
              "b_file",
              "uk",
              "c_file"
            ]
          }
        },
        { "target" => { "stat" => { "isdir" => true } } },
        { "target" => { "stat" => { "isdir" => false } } },
        { "target" => { "stat" => { "isdir" => true } } },
        { "target" => { "stat" => { "isdir" => false } } },
        { "target" => { "stat" => { "isdir" => true } } },
        { "target" => { "stat" => { "isdir" => false } } }
      ]

      @write = {}
      @execute = {}

      Yast.include self, "testsuite.rb"

      Yast.import "SquidErrorMessages"
      Yast.import "FileUtils"

      DUMP("GetLanguages()")
      TEST(-> { SquidErrorMessages.GetLanguages }, [@read, @write, @execute], nil)

      DUMP("")
      DUMP("GetLanguagesToComboBox()")
      TEST(-> { SquidErrorMessages.GetLanguagesToComboBox }, [
             @read,
             @write,
             @execute
           ], nil)

      DUMP("")
      DUMP("GetPath(\"en\")")
      TEST(-> { SquidErrorMessages.GetPath("en") }, [
             @read,
             @write,
             @execute
           ], nil)
      DUMP("GetPath(\"uk\")")
      TEST(-> { SquidErrorMessages.GetPath("uk") }, [
             @read,
             @write,
             @execute
           ], nil)

      DUMP("")
      DUMP(
        Ops.add(
          Ops.add(
            Ops.add("GetLanguageFromPath(", SquidErrorMessages.err_msg_dir),
            "/en"
          ),
          ")"
        )
      )
      TEST(lambda do
        SquidErrorMessages.GetLanguageFromPath(
          Ops.add(SquidErrorMessages.err_msg_dir, "/en")
        )
      end, [
        @read,
        @write,
        @execute
      ], nil)
      DUMP(
        Ops.add(
          Ops.add(
            Ops.add("GetLanguageFromPath(", SquidErrorMessages.err_msg_dir),
            "/uk"
          ),
          ")"
        )
      )
      TEST(lambda do
        SquidErrorMessages.GetLanguageFromPath(
          Ops.add(SquidErrorMessages.err_msg_dir, "/ru")
        )
      end, [
        @read,
        @write,
        @execute
      ], nil)

      nil
    end
  end
end

Yast::SquidErrorMessagesClient.new.main
