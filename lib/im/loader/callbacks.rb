# frozen_string_literal: true

module Im::Loader::Callbacks
  # Invoked from our decorated Kernel#require when a managed file is autoloaded.
  #
  # @private
  # @sig (String) -> void
  def on_file_autoloaded(file)
    cref = autoloads.delete(file)

    relative_cpath = relative_cpath(*cref)
    to_unload[relative_cpath] = [file, cref] if reloading_enabled?
    Im::Registry.unregister_autoload(file)

    if cdef?(*cref)
      obj = cget(*cref)
      if obj.is_a?(Module)
        register_module_name(obj, relative_cpath)
        Im::Registry.register_autoloaded_module(obj, relative_cpath, self)
      end
      log("constant #{relative_cpath} loaded from file #{file}") if logger
      run_on_load_callbacks(relative_cpath, obj, file) unless on_load_callbacks.empty?
    else
      raise Im::NameError.new("expected file #{file} to define constant #{cpath(*cref)}, but didn't", cref.last)
    end
  end

  # Invoked from our decorated Kernel#require when a managed directory is
  # autoloaded.
  #
  # @private
  # @sig (String) -> void
  def on_dir_autoloaded(dir)
    # Module#autoload does not serialize concurrent requires, and we handle
    # directories ourselves, so the callback needs to account for concurrency.
    #
    # Multi-threading would introduce a race condition here in which thread t1
    # autovivifies the module, and while autoloads for its children are being
    # set, thread t2 autoloads the same namespace.
    #
    # Without the mutex and subsequent delete call, t2 would reset the module.
    # That not only would reassign the constant (undesirable per se) but, worse,
    # the module object created by t2 wouldn't have any of the autoloads for its
    # children, since t1 would have correctly deleted its namespace_dirs entry.
    mutex2.synchronize do
      if cref = autoloads.delete(dir)
        autovivified_module = cref[0].const_set(cref[1], Module.new)
        relative_cpath = relative_cpath(*cref)
        register_module_name(autovivified_module, relative_cpath)
        Im::Registry.register_autoloaded_module(autovivified_module, relative_cpath, self)
        log("module #{relative_cpath} autovivified from directory #{dir}") if logger

        to_unload[relative_cpath] = [dir, cref] if reloading_enabled?

        # We don't unregister `dir` in the registry because concurrent threads
        # wouldn't find a loader associated to it in Kernel#require and would
        # try to require the directory. Instead, we are going to keep track of
        # these to be able to unregister later if eager loading.
        autoloaded_dirs << dir

        on_namespace_loaded(relative_cpath)

        run_on_load_callbacks(relative_cpath, autovivified_module, dir) unless on_load_callbacks.empty?
      end
    end
  end

  # Invoked when a class or module is created or reopened, either from the
  # tracer or from module autovivification. If the namespace has matching
  # subdirectories, we descend into them now.
  #
  # @private
  # @sig (Module) -> void
  def on_namespace_loaded(module_name)
    if dirs = namespace_dirs.delete(module_name)
      dirs.each do |dir|
        set_autoloads_in_dir(dir, cget(self, module_name))
      end
    end
  end

  private

  # @sig (String, Object) -> void
  def run_on_load_callbacks(cpath, value, abspath)
    # Order matters. If present, run the most specific one.
    callbacks = reloading_enabled? ? on_load_callbacks[cpath] : on_load_callbacks.delete(cpath)
    callbacks&.each { |c| c.call(value, abspath) }

    callbacks = on_load_callbacks[:ANY]
    callbacks&.each { |c| c.call(cpath, value, abspath) }
  end
end
