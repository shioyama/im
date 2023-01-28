# frozen_string_literal: true

module Im::ModuleConstAdded
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  private_constant :UNBOUND_METHOD_MODULE_NAME

  # We patch Module#const_added to track every time a constant is added to a
  # permanently-named module pointing to an Im-autoloaded constant. This is
  # important because the moment that an Im-autoloaded constant is attached to
  # a permanently named module, its name changes permanently. Although Im
  # internally avoids the use of absolute cpaths, ExplicitNamespace must use
  # them and thus we need to update its internal registry accordingly.
  #
  # @sig (Symbol) -> void
  def const_added(const_name)
    # If we are called from an autoload, no need to track.
    return super if autoload?(const_name)

    # Get the name of this module and only continue if it is a permanent name.
    return unless cpath = Im.permanent_cpath(self)

    # We know this is not an autoloaded constant, so it is safe to fetch the
    # value. We fetch the value, get it's object_id, and check the registry to
    # see if it is an Im-autoloaded module.
    relative_cpath, loader, references = Im::Registry.autoloaded_modules[const_get(const_name).object_id]
    return super unless loader

    # Update the context for this const add. This is important for reloading so
    # we can reset inbound references when the autoloaded module is unloaded.
    references << [self, const_name]

    # Update all absolute cpath references to this module by replacing all
    # references to the original cpath with the new, permanently-named cpath.
    #
    # For example, if we had a module loader::Foo::Bar, and loader::Foo was
    # assigned to Baz like this:
    #
    #   Baz = loader::Foo
    #
    # then we must update cpaths from a string like
    #
    #   "#<Im::Loader ...>::Foo::Bar"
    #
    # to
    #
    #   "Baz::Bar"
    #
    # To do this, we take the loader's module_prefix ("#<Im::Loader ...>::"),
    # append to it the relative cpath of the constant ("Foo") and replace that by the new
    # name ("Baz"), roughly like this:
    #
    #   "#<Im::Loader ...>::Foo::Bar".gsub(/^#{"#<Im::Loader ...>::Foo"}/, "Baz")
    #
    prefix = relative_cpath ? "#{loader.module_prefix}#{relative_cpath}" : loader.module_prefix.delete_suffix("::")
    ::Im::ExplicitNamespace.__update_cpaths(prefix, "#{cpath}::#{const_name}")

    super
  rescue NameError
    super
  end
end

::Module.prepend(Im::ModuleConstAdded)
