require "test_helper"

class TestDifferentRoot < LoaderTest
  test "setting a different root for loader" do
    files = [["foo.rb", "module Foo; end"]]

    mod = Module.new
    @loader = new_loader(root: mod, setup: false)

    with_setup(files) do
      assert mod::Foo
    end
  end
end
