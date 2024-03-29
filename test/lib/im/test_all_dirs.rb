# frozen_string_literal: true

require "test_helper"

class TestAllDirs < LoaderTest
  test "returns an empty array if no loaders are instantiated" do
    assert_empty Im::Loader.all_dirs
  end

  test "returns an empty array if there are loaders but they have no root dirs" do
    2.times { new_loader }
    assert_empty Im::Loader.all_dirs
  end

  test "returns the root directories of the registered loaders" do
    files = [
      ["loaderA/a.rb", "A = true"],
      ["loaderB/b.rb", "B = true"]
    ]
    with_files(files) do
      new_loader(dirs: "loaderA")
      new_loader(dirs: "loaderB")

      assert_equal ["#{Dir.pwd}/loaderA", "#{Dir.pwd}/loaderB"].to_set, Im::Loader.all_dirs
    end
  end
end
