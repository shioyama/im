# frozen_string_literal: true

require "test_helper"
require "fileutils"

class TestReloading < LoaderTest
  def silence_exceptions_in_threads
    original_report_on_exception = Thread.report_on_exception
    Thread.report_on_exception = false
    yield
  ensure
    Thread.report_on_exception = original_report_on_exception
  end

  test "enabling reloading after setup raises" do
    e = assert_raises(Im::Error) do
      loader = Im::Loader.new
      loader.setup
      loader.enable_reloading
    end
    assert_equal "cannot enable reloading after setup", e.message
  end

  test "enabling reloading is idempotent, even after setup" do
    assert loader.reloading_enabled? # precondition
    loader.setup
    loader.enable_reloading # should not raise
    assert loader.reloading_enabled?
  end

  test "reloading works if the flag is set (Object)" do
    files = [
      ["x.rb", "X = 1"],         # top-level
      ["y.rb", "module Y; end"], # explicit namespace
      ["y/a.rb", "Y::A = 1"],
      ["z/a.rb", "Z::A = 1"]     # implicit namespace
    ]
    with_setup(files) do
      assert_equal 1, loader::X
      assert_equal 1, loader::Y::A
      assert_equal 1, loader::Z::A

      y_hash = loader::Y.hash
      z_hash = loader::Z.hash

      File.write("x.rb", "X = 2")
      File.write("y/a.rb", "Y::A = 2")
      File.write("z/a.rb", "Z::A = 2")

      loader.reload

      assert_equal 2, loader::X
      assert_equal 2, loader::Y::A
      assert_equal 2, loader::Z::A

      assert loader::Y.hash != y_hash
      assert loader::Z.hash != z_hash

      assert_equal 2, loader::X
    end
  end

  test "reloading raises if the flag is not set" do
    e = assert_raises(Im::ReloadingDisabledError) do
      loader = Im::Loader.new
      loader.setup
      loader.reload
    end
    assert_equal "can't reload, please call loader.enable_reloading before setup", e.message
  end

  test "if reloading is disabled, autoloading metadata shrinks while autoloading (performance test)" do
    on_teardown do
      delete_loaded_feature "x.rb"
      delete_loaded_feature "y.rb"
      delete_loaded_feature "y/a.rb"
      delete_loaded_feature "z/a.rb"
    end

    files = [
      ["x.rb", "X = 1"],
      ["y.rb", "module Y; end"],
      ["y/a.rb", "Y::A = 1"],
      ["z/a.rb", "Z::A = 1"]
    ]
    with_files(files) do
      loader = new_loader(dirs: ".", enable_reloading: false)

      assert !loader.__autoloads.empty?

      assert_equal 1, loader::X
      assert_equal 1, loader::Y::A
      assert_equal 1, loader::Z::A

      assert loader.__autoloads.empty?
      assert loader.__to_unload.empty?
    end
  end

  test "if reloading is disabled, autoloading metadata shrinks while eager loading (performance test)" do
    on_teardown do
      delete_loaded_feature "x.rb"
      delete_loaded_feature "y.rb"
      delete_loaded_feature "y/a.rb"
      delete_loaded_feature "z/a.rb"
    end

    files = [
      ["x.rb", "X = 1"],
      ["y.rb", "module Y; end"],
      ["y/a.rb", "Y::A = 1"],
      ["z/a.rb", "Z::A = 1"]
    ]
    with_files(files) do
      loader = new_loader(dirs: ".", enable_reloading: false)

      assert !loader.__autoloads.empty?
      assert !Im::Registry.autoloads.empty?

      loader.eager_load

      assert loader.__autoloads.empty?
      assert Im::Registry.autoloads.empty?
      assert loader.__to_unload.empty?
    end
  end

  test "reloading supports deleted root directories" do
    files = [["rd1/x.rb", "X = 1"], ["rd2/y.rb", "Y = 1"]]
    with_setup(files) do
      assert loader::X
      assert loader::Y

      FileUtils.rm_rf("rd2")
      loader.reload

      assert loader::X
    end
  end

  test "you can eager load again after reloading" do
    $test_eager_load_after_reload = 0
    files = [["x.rb", "$test_eager_load_after_reload += 1; X = 1"]]
    with_setup(files) do
      loader.eager_load
      assert_equal 1, $test_eager_load_after_reload

      loader.reload

      loader.eager_load
      assert_equal 2, $test_eager_load_after_reload
    end
  end

  test "reload recovers from name errors (w/o on_unload callbacks)" do
    files = [["x.rb", "Y = :typo"]]
    with_setup(files) do
      assert_raises(Im::NameError) { loader::X }

      assert !loader.constants.include?(:X)
      assert !loader.const_defined?(:X, false)
      assert !loader.autoload?(:X)

      loader.reload
      File.write("x.rb", "X = true")

      assert loader.constants.include?(:X)
      assert loader.const_defined?(:X, false)
      assert loader.autoload?(:X)

      assert loader::X
    end
  end

  test "reload recovers from name errors (w/ on_unload callbacks)" do
    files = [["x.rb", "Y = :typo"]]
    with_setup(files) do
      loader.on_unload {}
      assert_raises(Im::NameError) { loader::X }

      assert !loader.constants.include?(:X)
      assert !loader.const_defined?(:X, false)
      assert !loader.autoload?(:X)

      loader.reload
      File.write("x.rb", "X = true")

      assert loader.constants.include?(:X)
      assert loader.const_defined?(:X, false)
      assert loader.autoload?(:X)

      assert loader::X
    end
  end

  test "raises if called before setup" do
    assert_raises(Im::SetupRequired) do
      loader.reload
    end
  end
end
