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

  test "setting Object as root" do
    on_teardown { remove_const :Foo, from: Object }

    files = [["foo.rb", "module Foo; end"]]

    @loader = new_loader(root: Object, setup: false)

    with_setup(files) do
      assert ::Foo
    end
  end
end
