# frozen_string_literal: true

require "test_helper"

class TestShadowedFiles < LoaderTest
  test "does not autoload from a file shadowed by an existing constant" do
    loader::X = 1

    files = [["x.rb", "X = 2"]]
    with_setup(files) do
      assert loader.__shadowed_file?(File.expand_path("x.rb"))

      assert_equal 1, loader::X
      loader.reload
      assert_equal 1, loader::X
    end
  end

  test "does not autoload from a file shadowed by another one managed by the same loader" do
    files = [["a/x.rb", "X = 1"], ["b/x.rb", "X = 2"]]
    with_files(files) do
      loader.push_dir("a")
      loader.push_dir("b")
      loader.setup

      assert !loader.__shadowed_file?(File.expand_path("a/x.rb"))
      assert loader.__shadowed_file?(File.expand_path("b/x.rb"))

      assert_equal 1, loader::X
      loader.reload
      assert_equal 1, loader::X
    end
  end
end
