# frozen_string_literal: true

require "test_helper"

class TestAutovivification < LoaderTest
  test "autoloads a simple constant in an autovivified module (Object)" do
    files = [["admin/x.rb", "Admin::X = true"]]
    with_setup(files) do
      assert_kind_of Module, loader::Admin
      assert loader::Admin::X
    end
  end

  test "autovivifies several levels in a row (Object)" do
    files = [["foo/bar/baz/woo.rb", "Foo::Bar::Baz::Woo = true"]]
    with_setup(files) do
      assert loader::Foo::Bar::Baz::Woo
    end
  end

  test "autoloads several constants from the same namespace (Object)" do
    files = [
      ["rd1/admin/hotel.rb", "class Admin::Hotel; end"],
      ["rd2/admin/hotels_controller.rb", "class Admin::HotelsController; end"]
    ]
    with_setup(files) do
      assert loader::Admin::Hotel
      assert loader::Admin::HotelsController
    end
  end

  test "does not register the namespace as explicit" do
    files = [
      ["rd1/admin/x.rb", "Admin::X = true"],
      ["rd2/admin/y.rb", "Admin::Y = true"]
    ]
    with_setup(files) do
      assert !Im::ExplicitNamespace.__registered?("Admin")
    end
  end

  test "autovivification is synchronized" do
    $test_admin_const_set_calls = 0
    $test_admin_const_set_queue = Queue.new

    files = [["admin/v2/user.rb", "class Admin::V2::User; end"]]
    with_setup(files) do
      assert loader::Admin

      loader_admin = loader::Admin
      def loader_admin.const_set(cname, mod)
        $test_admin_const_set_calls += 1
        $test_admin_const_set_queue << true
        sleep 0.1
        super
      end

      concurrent_autovivifications = [
        Thread.new {
          loader::Admin::V2
        },
        Thread.new {
          $test_admin_const_set_queue.pop()
          loader::Admin::V2
        }
      ]

      concurrent_autovivifications.each(&:join)

      assert_equal 1, $test_admin_const_set_calls
      assert $test_admin_const_set_queue.empty?
    end
  end

  test "defines no namespace for empty directories" do
    with_files([]) do
      FileUtils.mkdir("foo")
      loader.push_dir(".")
      loader.setup
      assert !loader.autoload?(:Foo)
    end
  end

  test "defines no namespace for empty directories (recursively)" do
    with_files([]) do
      FileUtils.mkdir_p("foo/bar/baz")
      loader.push_dir(".")
      loader.setup
      assert !loader.autoload?(:Foo)
    end
  end

  test "defines no namespace for directories whose files are all non-Ruby" do
    with_setup([["tasks/newsletter.rake", ""], ["assets/.keep", ""]]) do
      assert !loader.autoload?(:Tasks)
      assert !loader.autoload?(:Assets)
    end
  end

  test "defines no namespace for directories whose files are all non-Ruby (recursively)" do
    with_setup([["tasks/product/newsletter.rake", ""], ["assets/css/.keep", ""]]) do
      assert !loader.autoload?(:Tasks)
      assert !loader.autoload?(:Assets)
    end
  end

  test "defines no namespace for directories whose Ruby files are all ignored" do
    with_setup([["foo/bar/ignored.rb", "IGNORED"]]) do
      assert !loader.autoload?(:Foo)
    end
  end

  test "defines no namespace for directories that have Ruby files below ignored directories" do
    with_setup([["foo/ignored/baz.rb", "IGNORED"]]) do
      assert !loader.autoload?(:Foo)
    end
  end
end
