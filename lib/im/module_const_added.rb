# frozen_string_literal: true

module Im::ModuleConstAdded
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  private_constant :UNBOUND_METHOD_MODULE_NAME

  def const_added(const_name)
    return super if autoload?(const_name)

    name = UNBOUND_METHOD_MODULE_NAME.bind_call(self)
    return super unless name && !name.start_with?("#")

    module_name, loader, references = Im::Registry.autoloaded_modules[const_get(const_name).object_id]
    return super unless loader

    references << [self, const_name]
    prefix = module_name ? "#{loader.module_prefix}#{module_name}" : loader.module_prefix.delete_suffix("::")

    ::Im::ExplicitNamespace.__update_cpaths(prefix, /^#{prefix}/, "#{name}::#{const_name}")

    super
  rescue NameError
    super
  end
end

::Module.prepend(Im::ModuleConstAdded)
