# frozen_string_literal: true

require "test_helper"

class TestGemInflector < LoaderTest
  def with_setup
    files = [
      ["lib/my_gem.rb", <<-EOS],
        $gem_inflector_test_loader = Im::Loader.for_gem
        $gem_inflector_test_loader.enable_reloading
        $gem_inflector_test_loader.setup

        module $gem_inflector_test_loader::MyGem
        end
      EOS
      ["lib/my_gem/foo.rb", "MyGem::Foo = true"],
      ["lib/my_gem/version.rb", "MyGem::VERSION = '1.0.0'"],
      ["lib/my_gem/ns/version.rb", "MyGem::Ns::Version = true"]
    ]
    with_files(files) do
      with_load_path("lib") do
        assert require("my_gem")
        yield
      end
    end
  end

  test "the constant for my_gem/version.rb is inflected as VERSION" do
    with_setup { assert_equal "1.0.0", $gem_inflector_test_loader::MyGem::VERSION }
  end

  test "other possible version.rb are inflected normally" do
    with_setup { assert $gem_inflector_test_loader::MyGem::Ns::Version }
  end

  test "works as expected for other files" do
    with_setup { assert $gem_inflector_test_loader::MyGem::Foo }
  end
end
