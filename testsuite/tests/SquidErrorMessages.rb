# encoding: utf-8

module Yast
  class SquidErrorMessagesClient < Client
    def main
      # testedfiles: SquidErrorMessages.ycp

      @READ = [
        {
          "target" => {
            "dir" => [
              "Russian-1251",
              "a_file",
              "English",
              "b_file",
              "Simplify_Chinese",
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
      TEST(lambda { SquidErrorMessages.GetLanguages }, [@READ, @WRITE, @EXECUTE], nil)

      DUMP("")
      DUMP("GetLanguagesToComboBox()")
      TEST(lambda { SquidErrorMessages.GetLanguagesToComboBox }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)

      DUMP("")
      DUMP("GetPath(\"English\")")
      TEST(lambda { SquidErrorMessages.GetPath("English") }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)
      DUMP("GetPath(\"Simplify Chinese\")")
      TEST(lambda { SquidErrorMessages.GetPath("Simplify Chinese") }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)

      DUMP("")
      DUMP(
        Ops.add(
          Ops.add(
            Ops.add("GetLanguageFromPath(", SquidErrorMessages.err_msg_dir),
            "/English"
          ),
          ")"
        )
      )
      TEST(lambda do
        SquidErrorMessages.GetLanguageFromPath(
          Ops.add(SquidErrorMessages.err_msg_dir, "/English")
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
            "/Simplify_Chinese"
          ),
          ")"
        )
      )
      TEST(lambda do
        SquidErrorMessages.GetLanguageFromPath(
          Ops.add(SquidErrorMessages.err_msg_dir, "/Simplify_Chinese")
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
