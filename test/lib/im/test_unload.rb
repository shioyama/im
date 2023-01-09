# frozen_string_literal: true

require "test_helper"

class TestUnload < LoaderTest
  test "unload removes all autoloaded constants" do
    files = [
      ["user.rb", "class User; end"],
      ["admin/root.rb", "class Admin::Root; end"]
    ]
    with_setup(files) do
      assert loader::User
      assert loader::Admin::Root
      admin = loader::Admin

      loader.unload

      assert !loader.const_defined?(:User)
      assert !loader.const_defined?(:Admin)
      assert !admin.const_defined?(:Root)
    end
  end

  test "unload removes autoloaded constants, even if #name is overridden" do
    files = [["x.rb", <<~RUBY]]
      module X
        def self.name
          "Y"
        end
      end
    RUBY
    with_setup(files) do
      assert loader::X
      loader.unload
      assert !loader.const_defined?(:X)
    end
  end

  test "unload removes non-executed autoloads" do
    files = [["x.rb", "X = true"]]
    with_setup(files) do
      # This does not autolaod, see the compatibility test.
      assert loader.const_defined?(:X)
      loader.unload
      assert !loader.const_defined?(:X)
    end
  end

  test "unload clears internal caches" do
    files = [
      ["rd1/user.rb", "class User; end"],
      ["rd1/api/v1/users_controller.rb", "class Api::V1::UsersController; end"],
      ["rd1/admin/root.rb", "class Admin::Root; end"],
      ["rd2/user.rb", "class User; end"]
    ]
    with_setup(files) do
      assert loader::User
      assert loader::Api::V1::UsersController

      assert !loader.autoloads.empty?
      assert !loader.autoloaded_dirs.empty?
      assert !loader.to_unload.empty?
      assert !loader.namespace_dirs.empty?

      loader.unload

      assert loader.autoloads.empty?
      assert loader.autoloaded_dirs.empty?
      assert loader.to_unload.empty?
      assert loader.namespace_dirs.empty?
    end
  end

  test "unload does not assume autoloaded constants are still there" do
    files = [["x.rb", "X = true"]]
    with_setup(files) do
      assert loader::X
      assert loader.send(:remove_const, :X) # user removed the constant by hand
      loader.unload # should not raise
    end
  end

  test "already existing namespaces are not reset" do
    on_teardown do
      delete_loaded_feature "active_storage.rb"
    end

    files = [
      ["app/models/active_storage/blob.rb", "class ActiveStorage::Blob; end"]
    ]
    with_files(files) do
      with_load_path("lib") do
        loader::ActiveStorage = Module.new

        loader.push_dir("app/models")
        loader.setup

        assert loader::ActiveStorage::Blob
        loader.unload
        assert loader::ActiveStorage
      end
    end
  end

  test "unload clears explicit namespaces associated" do
    files = [
      ["a/m.rb", "module M; end"], ["a/m/n.rb", "M::N = true"],
      ["b/x.rb", "module X; end"], ["b/x/y.rb", "X::Y = true"],
    ]
    with_files(files) do
      la = new_loader(dirs: "a")
      assert Im::ExplicitNamespace.send(:cpaths)["#{la}::M"] == ["M", la]

      lb = new_loader(dirs: "b")
      assert Im::ExplicitNamespace.send(:cpaths)["#{lb}::X"] == ["X", lb]

      la.unload
      assert_nil Im::ExplicitNamespace.send(:cpaths)["#{la}::M"]
      assert Im::ExplicitNamespace.send(:cpaths)["#{lb}::X"] == ["X", lb]
    end
  end

  test "unload clears the set of shadowed files" do
    files = [
      ["a/m.rb", "module M; end"],
      ["b/m.rb", "module M; end"],
    ]
    with_files(files) do
      loader.push_dir("a")
      loader.push_dir("b")
      loader.setup

      assert !loader.shadowed_files.empty? # precondition
      loader.unload
      assert loader.shadowed_files.empty?
    end
  end

  test "unload clears state even if the autoload failed and the exception was rescued" do
    files = [["x.rb", "X_IS_NOT_DEFINED = true"]]
    with_setup(files) do
      begin
        loader::X
      rescue Im::NameError
        pass # precondition holds
      else
        flunk # precondition failed
      end

      loader.unload

      assert !loader.constants.include?(:X)
      assert !required?(files)
    end
  end

  test "raises if called before setup" do
    assert_raises(Im::SetupRequired) do
      loader.unload
    end
  end
end
