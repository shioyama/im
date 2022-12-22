# frozen_string_literal: true

module Im::RealModName
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  private_constant :UNBOUND_METHOD_MODULE_NAME

  # @sig (Module) -> String?
  def real_mod_name(mod)
    UNBOUND_METHOD_MODULE_NAME.bind_call(mod)
  end
end
