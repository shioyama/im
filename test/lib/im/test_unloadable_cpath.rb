# frozen_string_literal: true

require "test_helper"
require "set"

class TestUnloadableCpath < LoaderTest
  test "a loader that has loading nothing, has nothing to unload" do
    files = [["x.rb", "X = true"]]
    with_setup(files) do
      assert_empty loader.unloadable_cpaths
      assert !loader.unloadable_cpath?("X")
    end
  end

  test "a loader that loaded some stuff has that stuff to be unloaded if reloading is enabled" do
    files = [
      ["m/x.rb", "M::X = true"],
      ["m/y.rb", "M::Y = true"],
      ["z.rb", "Z = true"]
    ]
    with_setup(files) do
      assert loader::M::X

      assert_equal ["#{loader}::M", "#{loader}::M::X"], loader.unloadable_cpaths

      assert loader.unloadable_cpath?("#{loader}::M")
      assert loader.unloadable_cpath?("#{loader}::M::X")

      assert !loader.unloadable_cpath?("#{loader}::M::Y")
      assert !loader.unloadable_cpath?("#{loader}::Z")
    end
  end

  test "unloadable_cpaths returns actual constant paths even if #name is overridden" do
    files = [["m.rb", <<~RUBY], ["m/c.rb", "M::C = true"]]
      module M
        def self.name
          "X"
        end
      end
    RUBY
    with_setup(files) do
      assert loader::M::C
      assert loader.unloadable_cpath?("#{loader}::M::C")
    end
  end

  test "a loader that loaded some stuff has nothing to unload if reloading is disabled" do
    on_teardown do
      delete_loaded_feature "m/x.rb"
      delete_loaded_feature "m/y.rb"
      delete_loaded_feature "z.rb"
    end

    files = [
      ["m/x.rb", "M::X = true"],
      ["m/y.rb", "M::Y = true"],
      ["z.rb", "Z = true"]
    ]
    with_files(files) do
      loader = new_loader(dirs: ".", enable_reloading: false)

      assert loader::M::X
      assert loader::M::Y
      assert loader::Z

      assert_empty loader.unloadable_cpaths
      assert loader.to_unload.empty?
    end
  end
end
