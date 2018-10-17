# encoding: utf-8

module Yast
  class SquidErrorMessagesClient < Client
    def main
      # testedfiles: SquidErrorMessages.ycp

      @READ = [
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

      @WRITE = {}
      @EXECUTE = {}

      Yast.include self, "testsuite.rb"

      Yast.import "SquidErrorMessages"
      Yast.import "FileUtils"

      DUMP("GetLanguages()")
      TEST(-> { SquidErrorMessages.GetLanguages }, [@READ, @WRITE, @EXECUTE], nil)

      DUMP("")
      DUMP("GetLanguagesToComboBox()")
      TEST(-> { SquidErrorMessages.GetLanguagesToComboBox }, [
             @READ,
             @WRITE,
             @EXECUTE
           ], nil)

      DUMP("")
      DUMP("GetPath(\"en\")")
      TEST(-> { SquidErrorMessages.GetPath("en") }, [
             @READ,
             @WRITE,
             @EXECUTE
           ], nil)
      DUMP("GetPath(\"uk\")")
      TEST(-> { SquidErrorMessages.GetPath("uk") }, [
             @READ,
             @WRITE,
             @EXECUTE
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
        @READ,
        @WRITE,
        @EXECUTE
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
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)

      nil
    end
  end
end

Yast::SquidErrorMessagesClient.new.main
