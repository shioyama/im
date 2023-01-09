# frozen_string_literal: true

module Im::ModuleConstAdded
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  private_constant :UNBOUND_METHOD_MODULE_NAME

  def const_added(const_name)
    return super if autoload?(const_name)

    name = UNBOUND_METHOD_MODULE_NAME.bind_call(self)
    return super unless name && !name.start_with?("#")

    module_name, loader = Im::Registry.autoloaded_modules[const_get(const_name).object_id]
    return super unless loader

    prefix = "#{loader.module_prefix}#{module_name}"
    pattern = /^#{prefix}/
    replacement = "#{name}::#{const_name}"

    Im::ExplicitNamespace.send(:cpaths).transform_keys! do |key|
      key.start_with?(prefix) ? key.gsub(pattern, replacement) : key
    end

    super
  rescue NameError
    super
  end
end

::Module.prepend(Im::ModuleConstAdded)
