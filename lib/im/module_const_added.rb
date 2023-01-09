# frozen_string_literal: true

module Im::ModuleConstAdded
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  private_constant :UNBOUND_METHOD_MODULE_NAME

  def const_added(const_name)
    return super if autoload?(const_name)

    name = UNBOUND_METHOD_MODULE_NAME.bind_call(self)
    return super unless name && !name.start_with?("#")

    loader, cpath = Im::Registry.autoloaded_modules[const_get(const_name).object_id]
    return super unless loader

    replacement = "#{name}::#{const_name}"

    Im::ExplicitNamespace.__update_cpaths(cpath, replacement)
    loader.update_cpaths(cpath, replacement)

    super
  rescue NameError
    super
  end
end

::Module.prepend(Im::ModuleConstAdded)
