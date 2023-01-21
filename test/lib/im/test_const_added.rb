# frozen_string_literal: true

require "test_helper"

class TestConstAdded < LoaderTest
  def files
    [
      ["a.rb", <<-EOS1], ["a/b.rb", <<~EOS2], ["a/b/c.rb", <<~EOS3]
      module A; end
      EOS1
      module A
        module B
        end
      end
      EOS2
      module A
        module B
          module C
          end
        end
      end
      EOS3
    ]
  end

  test "loads nested constants correctly after root has been named" do
    on_teardown { remove_const :X, from: self.class }

    with_setup(files) do
      assert loader::A
      X = loader::A
      assert loader::A
      assert loader::A::B
      assert loader::A::B::C
      assert_equal(X::B::C, loader::A::B::C)
    end
  end

  test "multiple constant aliases" do
    on_teardown do
      remove_const :X, from: self.class
      remove_const :Y, from: self.class
    end

    with_setup(files) do
      assert loader::A
      X = loader::A
      assert loader::A
      Y = X
      assert loader::A::B
      assert loader::A::B::C
    end
  end

  test "compatible with reload" do
    on_teardown { remove_const :X, from: self.class }

    with_setup(files) do
      loader.enable_reloading
      X = loader::A::B
      assert(X::C)
      loader.reload
      assert(X::C)
    end
  end

  test "compatible with reloading of constants that have been aliased" do
    on_teardown do
      remove_const :X, from: self.class
      remove_const :Y, from: self.class
      remove_const :Z, from: self.class
    end

    with_setup(files) do
      loader.enable_reloading
      X = loader::A
      Y = loader::A
      Z = loader::A::B
      assert(X::B)
      assert(Y::B)
      assert(Z::C)
      loader.reload
      assert(X::B)
      assert(Y::B)
      assert(Z::C)
    end
  end

  test "named root" do
    on_teardown { remove_const :X, from: self.class }

    with_setup(files) do
      loader.enable_reloading
      X = loader
      assert(X::A)
      assert(X::A::B)
      loader.reload
      assert(X::A)
      assert(X::A::B)
    end
  end
end
