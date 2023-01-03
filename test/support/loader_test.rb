# frozen_string_literal: true

class LoaderTest < Minitest::Test
  TMP_DIR = File.expand_path("../tmp", __dir__)

  attr_reader :loader

  def setup
    @loader = new_loader(setup: false)
  end

  def new_loader(dirs: [], enable_reloading: true, setup: true)
    Im::Loader.new.tap do |loader|
      Array(dirs).each { |dir| loader.push_dir(dir) }
      loader.enable_reloading if enable_reloading
      loader.setup            if setup
    end
  end

  def reset_constants
    Im::Registry.loaders.each do |loader|
      begin
        loader.unload
      rescue Im::SetupRequired
      end
    end
  end

  def reset_registry
    Im::Registry.loaders.clear
    Im::Registry.gem_loaders_by_root_file.clear
    Im::Registry.autoloads.clear
    Im::Registry.inceptions.clear
  end

  def reset_explicit_namespace
    Im::ExplicitNamespace.send(:cpaths).clear
    Im::ExplicitNamespace.send(:tracer).disable
  end

  def teardown
    reset_constants
    reset_registry
    reset_explicit_namespace
  end

  def mkdir_test
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
  end

  def with_files(files, rm: true)
    mkdir_test

    Dir.chdir(TMP_DIR) do
      files.each do |fname, contents|
        FileUtils.mkdir_p(File.dirname(fname))
        File.write(fname, contents)
      end
      yield
    end
  ensure
    mkdir_test if rm
  end

  def with_load_path(dirs = loader.dirs)
    dirs = Array(dirs).map { |dir| File.expand_path(dir) }
    dirs.each { |dir| $LOAD_PATH.push(dir) }
    yield
  ensure
    dirs.each { |dir| $LOAD_PATH.delete(dir) }
  end

  def with_setup(files = [], dirs: nil, load_path: nil, rm: true)
    with_files(files, rm: rm) do
      dirs ||= files.map do |file|
        file[0] =~ %r{\A(rd\d+)/} ? $1 : "."
      end.uniq
      dirs.each { |dir| loader.push_dir(dir) }

      files.each do |file|
        if File.basename(file[0]) == "ignored.rb"
          loader.ignore(file[0])
        elsif file[0] =~ %r{\A(ignored|.+/ignored)/}
          loader.ignore($1)
        end

        if file[0] =~ %r{\A(collapsed|.+/collapsed)/}
          loader.collapse($1)
        end
      end

      loader.setup
      if load_path
        with_load_path(load_path) { yield }
      else
        yield
      end
    end
  end

  def required?(file_or_files)
    if file_or_files.is_a?(String)
      $LOADED_FEATURES.include?(File.expand_path(file_or_files, TMP_DIR))
    elsif file_or_files[0].is_a?(String)
      required?(file_or_files[0])
    else
      file_or_files.all? { |f| required?(f) }
    end
  end

  def assert_abspath(expected, actual)
    assert_equal(File.expand_path(expected, TMP_DIR), actual)
  end
end
