# frozen_string_literal: true

require "test_helper"
require "pathname"

class TesPushDir < LoaderTest
  def check_dirs
    root_dirs = loader.__root_dirs

    non_ignored_root_dirs = root_dirs.reject { |dir| loader.send(:ignored_path?, dir) }.to_set

    dirs = loader.dirs
    assert_equal non_ignored_root_dirs, dirs.to_set
    assert dirs.frozen?

    dirs = loader.dirs(ignored: true)
    assert_equal root_dirs, dirs.to_set
    assert dirs.frozen?
  end

  test "accepts dirs as strings and associates them to the Object namespace" do
    loader.push_dir(".")
    check_dirs
  end

  test "accepts dirs as pathnames and associates them to the Object namespace" do
    loader.push_dir(Pathname.new("."))
    check_dirs
  end

  test "there can be several root directories" do
    files = [["rd1/x.rb", "X = 1"], ["rd2/y.rb", "Y = 1"], ["rd3/z.rb", "Z = 1"]]
    with_setup(files) do
      check_dirs
    end
  end

  test "there can be several root directories, some of them may be ignored" do
    files = [["rd1/x.rb", "X = 1"], ["rd2/y.rb", "Y = 1"], ["rd3/z.rb", "Z = 1"]]
    with_files(files) do
      loader.push_dir("rd1")
      loader.push_dir("rd2")
      loader.push_dir("rd3")
      loader.ignore("rd2")
      check_dirs
    end
  end

  test "raises on non-existing directories" do
    dir = File.expand_path("non-existing")
    e = assert_raises(Im::Error) { loader.push_dir(dir) }
    assert_equal "the root directory #{dir} does not exist", e.message
  end
end
