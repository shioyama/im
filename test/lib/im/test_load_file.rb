require "pathname"
require "test_helper"

class TestLoadFile < LoaderTest
  test "loads a top-level file" do
    files = [["x.rb", "X = 1"]]
    with_setup(files) do
      loader.load_file("x.rb")
      assert required?(files[0])
    end
  end

  test "loads a top-level file (Pathname)" do
    files = [["x.rb", "X = 1"]]
    with_setup(files) do
      loader.load_file(Pathname.new("x.rb"))
      assert required?(files[0])
    end
  end

  test "loads a namespaced file" do
    files = [["m/x.rb", "M::X = 1"]]
    with_setup(files) do
      loader.load_file("m/x.rb")
      assert required?(files[0])
    end
  end

  test "supports collapsed directories" do
    files = [["m/collapsed/x.rb", "M::X = 1"]]
    with_setup(files) do
      loader.load_file("m/collapsed/x.rb")
      assert required?(files[0])
    end
  end
end

class TestLoadFileErrors < LoaderTest
  test "raises if the argument does not exist" do
    with_setup do
      e = assert_raises { loader.load_file("foo.rb") }
      assert_equal "#{File.expand_path('foo.rb')} does not exist", e.message
    end
  end

  test "raises if the argument is a directory" do
    with_setup([["m/x.rb", "M::X = 1"]]) do
      e = assert_raises { loader.load_file("m") }
      assert_equal "#{File.expand_path('m')} is not a Ruby file", e.message
    end
  end

  test "raises if the argument is a file, but does not have .rb extension" do
    with_setup([["README.md", ""]]) do
      e = assert_raises { loader.load_file("README.md") }
      assert_equal "#{File.expand_path('README.md')} is not a Ruby file", e.message
    end
  end

  test "raises if the argument is ignored" do
    with_setup([["ignored.rb", "IGNORED"]]) do
      e = assert_raises { loader.load_file("ignored.rb") }
      assert_equal "#{File.expand_path('ignored.rb')} is ignored", e.message
    end
  end

  test "raises if the argument is a descendant of an ignored directory" do
    with_setup([["ignored/n/x.rb", "IGNORED"]]) do
      e = assert_raises { loader.load_file("ignored/n/x.rb") }
      assert_equal "#{File.expand_path('ignored/n/x.rb')} is ignored", e.message
    end
  end

  test "raises if the argument lives in an ignored root directory" do
    files = [["ignored/n/x.rb", "IGNORED"]]
    with_setup(files, dirs: %w(ignored)) do
      e = assert_raises { loader.load_file("ignored/n/x.rb") }
      assert_equal "#{File.expand_path('ignored/n/x.rb')} is ignored", e.message
    end
  end

  test "raises if the file exists, but it is not managed by this loader" do
    files = [["rd1/x.rb", "X = 1"], ["external/x.rb", ""]]
    with_setup(files, dirs: %w(rd1)) do
      e = assert_raises { loader.load_file("external/x.rb") }
      assert_equal "I do not manage #{File.expand_path('external/x.rb')}", e.message
    end
  end

  test "raises if the file is shadowed" do
    files = [["rd1/x.rb", "X = 1"], ["rd2/x.rb", "SHADOWED"]]
    with_setup(files) do
      e = assert_raises { loader.load_file("rd2/x.rb") }
      assert_equal "#{File.expand_path('rd2/x.rb')} is shadowed", e.message
    end
  end
end
