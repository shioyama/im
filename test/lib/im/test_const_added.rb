# frozen_string_literal: true

require "test_helper"

class TestConstAdded < LoaderTest
  test "loads nested constants correctly after root has been named" do
    files = [
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
    files = [
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
    skip "not working yet"

    files = [
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

    with_setup(files) do
      loader.enable_reloading
      X = loader::A::B
      assert(X::C)
      loader.reload
      assert(X::C)
    end
  end

  test "compatible with reloading of constants that have been aliased" do
    skip "not working yet"

    files = [
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

    with_setup(files) do
      loader.enable_reloading
      X = loader::A
      Y = loader::A::B
      assert(X::B)
      assert(Y::C)
      loader.reload
      assert(X::B)
      assert(Y::C)
    end
  end
end
