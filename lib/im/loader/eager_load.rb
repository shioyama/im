module Im::Loader::EagerLoad
  # Eager loads all files in the root directories, recursively. Files do not
  # need to be in `$LOAD_PATH`, absolute file names are used. Ignored and
  # shadowed files are not eager loaded. You can opt-out specifically in
  # specific files and directories with `do_not_eager_load`, and that can be
  # overridden passing `force: true`.
  #
  # @sig (true | false) -> void
  def eager_load(force: false)
    mutex.synchronize do
      break if @eager_loaded
      raise Im::SetupRequired unless @setup

      log("eager load start") if logger

      actual_roots.each do |root_dir|
        actual_eager_load_dir(root_dir, self, force: force)
      end

      autoloaded_dirs.each do |autoloaded_dir|
        Im::Registry.unregister_autoload(autoloaded_dir)
      end
      autoloaded_dirs.clear

      @eager_loaded = true

      log("eager load end") if logger
    end
  end

  # @sig (String | Pathname) -> void
  def eager_load_dir(path)
    raise Im::SetupRequired unless @setup

    abspath = File.expand_path(path)

    raise Im::Error.new("#{abspath} is not a directory") unless dir?(abspath)

    cnames = []

    found_root = false
    walk_up(abspath) do |dir|
      return if ignored_path?(dir)
      return if eager_load_exclusions.member?(dir)

      break if found_root = root_dirs.include?(dir)

      unless collapse?(dir)
        basename = File.basename(dir)
        cnames << inflector.camelize(basename, dir).to_sym
      end
    end

    raise Im::Error.new("I do not manage #{abspath}") unless found_root

    return if @eager_loaded

    namespace = self
    cnames.reverse_each do |cname|
      # Can happen if there are no Ruby files. This is not an error condition,
      # the directory is actually managed. Could have Ruby files later.
      return unless cdef?(namespace, cname)
      namespace = cget(namespace, cname)
    end

    # A shortcircuiting test depends on the invocation of this method. Please
    # keep them in sync if refactored.
    actual_eager_load_dir(abspath, namespace)
  end

  # @sig (Module) -> void
  def eager_load_namespace(mod)
    raise Im::SetupRequired unless @setup

    unless mod.is_a?(Module)
      raise Im::Error, "#{mod.inspect} is not a class or module object"
    end

    return if @eager_loaded

    mod_name = Im.cpath(mod)

    actual_roots.each do |root_dir|
      if mod.equal?(self)
        # A shortcircuiting test depends on the invocation of this method.
        # Please keep them in sync if refactored.
        actual_eager_load_dir(root_dir, self)
      else
        eager_load_child_namespace(mod, mod_name, root_dir)
      end
    end
  end

  # Loads the given Ruby file.
  #
  # Raises if the argument is ignored, shadowed, or not managed by the receiver.
  #
  # The method is implemented as `constantize` for files, in a sense, to be able
  # to descend orderly and make sure the file is loadable.
  #
  # @sig (String | Pathname) -> void
  def load_file(path)
    abspath = File.expand_path(path)

    raise Im::Error.new("#{abspath} does not exist") unless File.exist?(abspath)
    raise Im::Error.new("#{abspath} is not a Ruby file") if dir?(abspath) || !ruby?(abspath)
    raise Im::Error.new("#{abspath} is ignored") if ignored_path?(abspath)

    basename = File.basename(abspath, ".rb")
    base_cname = inflector.camelize(basename, abspath).to_sym

    root_included = false
    cnames = []

    walk_up(File.dirname(abspath)) do |dir|
      raise Im::Error.new("#{abspath} is ignored") if ignored_path?(dir)

      break if root_included = root_dirs.include?(dir)

      unless collapse?(dir)
        basename = File.basename(dir)
        cnames << inflector.camelize(basename, dir).to_sym
      end
    end

    raise Im::Error.new("I do not manage #{abspath}") unless root_included

    namespace = self
    cnames.reverse_each do |cname|
      namespace = cget(namespace, cname)
    end

    raise Im::Error.new("#{abspath} is shadowed") if shadowed_file?(abspath)

    cget(namespace, base_cname)
  end

  # The caller is responsible for making sure `namespace` is the namespace that
  # corresponds to `dir`.
  #
  # @sig (String, Module, Boolean) -> void
  private def actual_eager_load_dir(dir, namespace, force: false)
    honour_exclusions = !force
    return if honour_exclusions && excluded_from_eager_load?(dir)

    log("eager load directory #{dir} start") if logger

    queue = [[dir, namespace]]
    while to_eager_load = queue.shift
      dir, namespace = to_eager_load

      ls(dir) do |basename, abspath|
        next if honour_exclusions && eager_load_exclusions.member?(abspath)

        if ruby?(abspath)
          if (cref = autoloads[abspath]) && !shadowed_file?(abspath)
            cget(*cref)
          end
        else
          if collapse?(abspath)
            queue << [abspath, namespace]
          else
            cname = inflector.camelize(basename, abspath).to_sym
            queue << [abspath, cget(namespace, cname)]
          end
        end
      end
    end

    log("eager load directory #{dir} end") if logger
  end

  # In order to invoke this method, the caller has to ensure `child` is a
  # strict namespace descendendant of `root_namespace`.
  #
  # @sig (Module, String, Module, Boolean) -> void
  private def eager_load_child_namespace(child, child_name, root_dir)
    suffix = child_name
    suffix = suffix.delete_prefix("#{self}::")

    # These directories are at the same namespace level, there may be more if
    # we find collapsed ones. As we scan, we look for matches for the first
    # segment, and store them in `next_dirs`. If there are any, we look for
    # the next segments in those matches. Repeat.
    #
    # If we exhaust the search locating directories that match all segments,
    # we just need to eager load those ones.
    dirs = [root_dir]
    next_dirs = []

    suffix.split("::").each do |segment|
      while dir = dirs.shift
        ls(dir) do |basename, abspath|
          next unless dir?(abspath)

          if collapse?(abspath)
            dirs << abspath
          elsif segment == inflector.camelize(basename, abspath)
            next_dirs << abspath
          end
        end
      end

      return if next_dirs.empty?

      dirs.replace(next_dirs)
      next_dirs.clear
    end

    dirs.each do |dir|
      actual_eager_load_dir(dir, child)
    end
  end
end
