# frozen_string_literal: true

require "test_helper"

class TestMultipleLoaders < LoaderTest
  test "multiple dependent loaders" do
    files = [
      ["lib0/app0.rb", <<-EOS],
        module App0
          $test_multiple_loaders_l1::App1
        end
      EOS
      ["lib0/app0/foo.rb", <<-EOS],
        class App0::Foo
          $test_multiple_loaders_l1::App1::Foo
        end
      EOS
      ["lib1/app1/foo.rb", <<-EOS],
        class App1::Foo
          $test_multiple_loaders_l0::App0
        end
      EOS
      ["lib1/app1/foo/bar/baz.rb", <<-EOS]
        class App1::Foo::Bar::Baz
          $test_multiple_loaders_l0::App0::Foo
        end
      EOS
    ]
    with_files(files) do
      $test_multiple_loaders_l0 = new_loader(dirs: "lib0")
      $test_multiple_loaders_l1 = new_loader(dirs: "lib1")

      assert $test_multiple_loaders_l0::App0::Foo
      assert $test_multiple_loaders_l1::App1::Foo::Bar::Baz
    end
  end
end
