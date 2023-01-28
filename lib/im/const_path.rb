# frozen_string_literal: true

module Im
  module ConstPath
    UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
    UNBOUND_METHOD_MODULE_TO_S = Module.instance_method(:to_s)
    private_constant :UNBOUND_METHOD_MODULE_NAME, :UNBOUND_METHOD_MODULE_TO_S

    # @sig (Module) -> String
    def cpath(mod)
      real_mod_name(mod) || real_mod_to_s(mod)
    end

    # @sig (Module) -> String?
    def permanent_cpath(mod)
      name = real_mod_name(mod)
      return name unless temporary_name?(name)
    end

    # @sig (Module) -> Boolean
    def permanent_cpath?(mod)
      !temporary_cpath?(mod)
    end

    # @sig (Module) -> Boolean
    def temporary_cpath?(mod)
      temporary_name?(real_mod_name(mod))
    end

    private

    # @sig (Module) -> String
    def real_mod_to_s(mod)
      UNBOUND_METHOD_MODULE_TO_S.bind_call(mod)
    end

    # @sig (Module) -> String?
    def real_mod_name(mod)
      UNBOUND_METHOD_MODULE_NAME.bind_call(mod)
    end

    # @sig (String) -> Boolean
    def temporary_name?(name)
      # There should be a nicer way to get this in Ruby.
      name.nil? || name.start_with?("#")
    end
  end
end
