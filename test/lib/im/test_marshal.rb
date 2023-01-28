# frozen_string_literal: true

require "test_helper"

class TestMarshal < LoaderTest
  test "Marshal.load autoloads a top-level class" do
    on_teardown { remove_const :C, from: self.class }

    files = [["c.rb", "class C; end"]]
    with_setup(files) do
      C = loader::C
      str = Marshal.dump(C.new)
      loader.reload
      assert_instance_of C, Marshal.load(str)
    end
  end

  test "Marshal.load autoloads a namespaced class (implicit)" do
    on_teardown { remove_const :M, from: self.class }

    files = [["m/n/c.rb", "class M::N::C; end"]]
    with_setup(files) do
      M = loader::M
      str = Marshal.dump(M::N::C.new)
      loader.reload
      assert_instance_of M::N::C, Marshal.load(str)
    end
  end

  test "Marshal.load autoloads a namespaced class (explicit)" do
    on_teardown { remove_const :M, from: self.class }

    files = [
      ["m.rb", "module M; end"],
      ["m/n/c.rb", "class M::N::C; end"]
    ]
    with_setup(files) do
      M = loader::M
      str = Marshal.dump(M::N::C.new)
      loader.reload
      assert_instance_of M::N::C, Marshal.load(str)
    end
  end

  test "Marshal.load autoloads several classes" do
    on_teardown do
      remove_const :C, from: self.class
      remove_const :D, from: self.class
    end

    files = [
      ["c.rb", "class C; end"],
      ["d.rb", "class D; end"]
    ]
    with_setup(files) do
      C = loader::C
      D = loader::D
      str = Marshal.dump([C.new, D.new])
      loader.reload
      loaded = Marshal.load(str)
      assert_instance_of C, loaded[0]
      assert_instance_of D, loaded[1]
    end
  end
end
