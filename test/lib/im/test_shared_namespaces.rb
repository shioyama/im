# frozen_string_literal: true

require "test_helper"

class TestSharedNamespaces < LoaderTest
  test "autoloads from a shared implicit namespace" do
    mod = Module.new
    loader::M = mod

    files = [["m/x.rb", "M::X = true"]]
    with_setup(files) do
      assert loader::M::X
      loader.reload
      assert_same mod, loader::M
      assert loader::M::X
    end
  end

  test "autoloads from a shared explicit namespace" do
    mod = Module.new
    loader::M = mod

    files = [
      ["m.rb", "class M; end"],
      ["m/x.rb", "M::X = true"]
    ]
    with_setup(files) do
      assert loader::M::X
      loader.reload
      assert_same mod, loader::M
      assert loader::M::X
    end
  end
end
