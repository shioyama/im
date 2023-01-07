# frozen_string_literal: true

module Im::RealModName
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  UNBOUND_METHOD_MODULE_TO_S = Module.instance_method(:to_s)
  private_constant :UNBOUND_METHOD_MODULE_NAME, :UNBOUND_METHOD_MODULE_TO_S

  # @sig (Module) -> String?
  def real_mod_name(mod)
    UNBOUND_METHOD_MODULE_NAME.bind_call(mod) || UNBOUND_METHOD_MODULE_TO_S.bind_call(mod)
  end
end
