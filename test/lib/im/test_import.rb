# frozen_string_literal: true

require "test_helper"

class TestImport < LoaderTest
  include Im

  def with_setup
    files = [
      ["lib/my_gem.rb", <<-EOS],
        $import_test_loader = Im::Loader.for_gem
        $import_test_loader.setup

        module $import_test_loader::MyGem
        end
      EOS
      ["lib/my_gem/foo.rb", "MyGem::Foo = true"],
    ]
    with_files(files) do
      with_load_path("lib") do
        yield
      end
    end
  end

  test "import returns loader for gem" do
    on_teardown { $LOADED_FEATURES.pop }

    with_setup do
      require "my_gem"
      assert_equal import("my_gem"), $import_test_loader
    end
  end

  test "import is also provided as a class method" do
    on_teardown { $LOADED_FEATURES.pop }

    with_setup do
      require "my_gem"
      assert_equal Im.import("my_gem"), $import_test_loader
    end
  end
end
