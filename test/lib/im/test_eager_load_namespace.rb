require "test_helper"

class TestEagerLoadNamespaceWithObjectRootNamespace < LoaderTest
  test "eager loads everything" do
    files = [["x.rb", "X = 1"], ["m/x.rb", "M::X = 1"]]
    with_setup(files) do
      loader.eager_load_namespace(Object)

      assert required?(files)
    end
  end

  test "shortcircuits if eager loaded" do
    with_setup do
      loader.eager_load

      # Dirty way to prove we shortcircuit.
      def loader.actual_eager_load_dir(*)
        raise
      end

      begin
        loader.eager_load_namespace(Object)
      rescue
        flunk
      else
        pass
      end
    end
  end

  test "does not assume the namespace has a name" do
    files = [["x.rb", "X = 1"]]
    with_setup(files) do
      loader.eager_load_namespace(Module.new)

      assert !required?(files[0])
    end
  end

  test "eager loads everything (multiple root directories)" do
    files = [
      ["rd1/x.rb", "X = 1"],
      ["rd1/m/x.rb", "M::X = 1"],
      ["rd2/y.rb", "Y = 1"],
      ["rd2/m/y.rb", "M::Y = 1"]
    ]
    with_setup(files) do
      loader.eager_load_namespace(Object)

      assert required?(files)
    end
  end

  test "supports collapsed directories" do
    files = [
      ["rd1/collapsed/m/x.rb", "M::X = 1"],
      ["rd2/y.rb", "Y = 1"],
      ["rd2/m/y.rb", "M::Y = 1"]
    ]
    with_setup(files) do
      loader.eager_load_namespace(M)
      assert required?(files[0])
      assert !required?(files[1])
      assert required?(files[2])
    end
  end

  test "eager loads everything (nested root directories)" do
    files = [
      ["x.rb", "X = 1"],
      ["m/x.rb", "M::X = 1"],
      ["nested/y.rb", "Y = 1"],
      ["nested/m/y.rb", "M::Y = 1"]
    ]
    with_setup(files, dirs: %w(. nested)) do
      loader.eager_load_namespace(Object)

      assert required?(files)
    end
  end

  test "eager loads a managed namespace" do
    files = [["x.rb", "X = 1"], ["m/x.rb", "M::X = 1"]]
    with_setup(files) do
      loader.eager_load_namespace(M)

      assert !required?(files[0])
      assert required?(files[1])
    end
  end

  test "eager loading a non-managed namespace does not raise" do
    files = [["x.rb", "X = 1"]]
    with_setup(files) do
      loader.eager_load_namespace(self.class)

      assert !required?(files[0])
    end
  end

  test "does not eager load ignored files" do
    files = [["x.rb", "X = 1"], ["ignored.rb", "IGNORED"]]
    with_setup(files) do
      loader.eager_load_namespace(Object)

      assert required?(files[0])
      assert !required?(files[1])
    end
  end

  test "does not eager load shadowed files" do
    files = [["rd1/x.rb", "X = 1"], ["rd2/x.rb", "X = 1"]]
    with_setup(files) do
      loader.eager_load_namespace(Object)

      assert required?(files[0])
      assert !required?(files[1])
    end
  end

  test "skips root directories which are excluded from eager loading (Object)" do
    files = [["rd1/a.rb", "A = 1"], ["rd2/b.rb", "B = 1"]]
    with_setup(files) do
      loader.do_not_eager_load("rd1")
      loader.eager_load_namespace(Object)

      assert !required?(files[0])
      assert required?(files[1])
    end
  end

  test "skips directories which are excluded from eager loading (namespace, ancestor)" do
    files = [["rd1/m/a.rb", "M::A = 1"], ["rd2/m/b.rb", "M::B = 1"]]
    with_setup(files) do
      loader.do_not_eager_load("rd1/m")
      loader.eager_load_namespace(Object)

      assert !required?(files[0])
      assert required?(files[1])
    end
  end

  test "skips directories which are excluded from eager loading (namespace, self)" do
    files = [["rd1/m/a.rb", "M::A = 1"], ["rd2/m/b.rb", "M::B = 1"]]
    with_setup(files) do
      loader.do_not_eager_load("rd1/m")
      loader.eager_load_namespace(M)

      assert !required?(files[0])
      assert required?(files[1])
    end
  end

  test "skips directories which are excluded from eager loading (namespace, descendant)" do
    files = [["rd1/m/n/a.rb", "M::N::A = 1"], ["rd2/m/n/b.rb", "M::N::B = 1"]]
    with_setup(files) do
      loader.do_not_eager_load("rd1/m")
      loader.eager_load_namespace(M::N)

      assert !required?(files[0])
      assert required?(files[1])
    end
  end

  test "does not eager load namespaces from other loaders" do
    files = [["a/m/x.rb", "M::X = 1"], ["b/m/y.rb", "M::Y = 1"]]
    with_files(files) do
      loader.push_dir("a")
      loader.setup

      new_loader(dirs: "b").eager_load_namespace(M)

      assert !required?(files[0])
      assert required?(files[1])
    end
  end

  test "raises if the argument is not a class or module object" do
    with_setup do
      e = assert_raises(Im::Error) do
        loader.eager_load_namespace(self.class.name)
      end
      assert_equal %Q("#{self.class.name}" is not a class or module object), e.message
    end
  end

  test "raises if the argument is not a class or module object, even if eager loaded" do
    with_setup do
      loader.eager_load
      e = assert_raises(Im::Error) do
        loader.eager_load_namespace(self.class.name)
      end
      assert_equal %Q("#{self.class.name}" is not a class or module object), e.message
    end
  end
end
