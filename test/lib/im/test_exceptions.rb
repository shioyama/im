# frozen_string_literal: true

require "test_helper"

class TestExceptions < LoaderTest
  # We cannot test error.message only because after
  #
  #   https://github.com/ruby/ruby/commit/e94604966572bb43fc887856d54aa54b8e9f7719
  #
  # error.message includes the line of code that raised.
  def assert_error_message(message, error)
    assert_equal message, error.message.lines.first.chomp
  end

  test "raises NameError if the expected constant is not defined" do
    files = [["typo.rb", "TyPo = 1"]]
    with_setup(files) do
      typo_rb = File.expand_path("typo.rb")
      error = assert_raises(Im::NameError) { loader::Typo }
      assert_error_message "expected file #{typo_rb} to define constant #{loader}::Typo, but didn't", error
      assert_equal :Typo, error.name
    end
  end

  test "eager loading raises NameError if files do not define the expected constants" do
    files = [["x.rb", ""]]
    with_setup(files) do
      x_rb = File.expand_path("x.rb")
      error = assert_raises(Im::NameError) { loader.eager_load }
      assert_error_message "expected file #{x_rb} to define constant #{loader}::X, but didn't", error
      assert_equal :X, error.name
    end
  end

  test "eager loading raises NameError if a namespace has not been loaded yet" do
    on_teardown do
      delete_loaded_feature 'cli/x.rb'
    end

    files = [["cli/x.rb", "module CLI; X = 1; end"]]
    with_setup(files) do
      cli_x_rb = File.expand_path("cli/x.rb")
      error = assert_raises(Im::NameError) { loader.eager_load }
      assert_error_message "expected file #{cli_x_rb} to define constant #{loader}::Cli::X, but didn't", error
      assert_equal :X, error.name
    end
  end

  test "raises if the file does" do
    files = [["raises.rb", "Raises = 1; raise 'foo'"]]
    with_setup(files, rm: false) do
      assert_raises(RuntimeError, "foo") { loader::Raises }
    end
  end

  test "raises Im::NameError if the inflector returns an invalid constant name for a file" do
    files = [["foo-bar.rb", "FooBar = 1"]]
    error = assert_raises Im::NameError do
      with_setup(files) {}
    end
    assert_equal :"Foo-bar", error.name
    assert_includes error.message, "wrong constant name Foo-bar"
    assert_includes error.message, "Tell Im to ignore this particular file."
  end

  test "raises Im::NameError if the inflector returns an invalid constant name for a directory" do
    files = [["foo-bar/baz.rb", "FooBar::Baz = 1"]]
    error = assert_raises Im::NameError do
      with_setup(files) {}
    end
    assert_equal :"Foo-bar", error.name
    assert_includes error.message, "wrong constant name Foo-bar"
    assert_includes error.message, "Tell Im to ignore this particular directory."
  end
end
