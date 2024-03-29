# frozen_string_literal: true

require "test_helper"

class TestCallbacks < LoaderTest
  test "autoloading a file triggers on_file_autoloaded" do
    def loader.on_file_autoloaded(file)
      if file == File.expand_path("x.rb")
        $on_file_autoloaded_called = true
      end
      super
    end

    files = [["x.rb", "X = true"]]
    with_setup(files) do
      $on_file_autoloaded_called = false
      assert loader::X
      assert $on_file_autoloaded_called
    end
  end

  test "requiring an autoloadable file triggers on_file_autoloaded" do
    def loader.on_file_autoloaded(file)
      if file == File.expand_path("y.rb")
        $on_file_autoloaded_called = true
      end
      super
    end

    files = [
      ["x.rb", "X = true"],
      ["y.rb", "Y = X"]
    ]
    with_setup(files, load_path: ".") do
      $on_file_autoloaded_called = false
      require "y"
      assert loader::Y
      assert $on_file_autoloaded_called
    end
  end

  test "autoloading a directory triggers on_dir_autoloaded" do
    def loader.on_dir_autoloaded(dir)
      if dir == File.expand_path("m")
        $on_dir_autoloaded_called = true
      end
      super
    end

    files = [["m/x.rb", "M::X = true"]]
    with_setup(files) do
      $on_dir_autoloaded_called = false
      assert loader::M::X
      assert $on_dir_autoloaded_called
    end
  end
end
