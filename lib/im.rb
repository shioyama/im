# frozen_string_literal: true

module Im
  require_relative "im/real_mod_name"
  require_relative "im/internal"
  require_relative "im/loader"
  require_relative "im/gem_loader"
  require_relative "im/registry"
  require_relative "im/explicit_namespace"
  require_relative "im/inflector"
  require_relative "im/gem_inflector"
  require_relative "im/kernel"
  require_relative "im/error"
  require_relative "im/version"

  # This is a dangerous method.
  #
  # @experimental
  # @sig () -> void
  def self.with_loader
    loader = Im::Loader.new
    yield loader
  ensure
    loader.unregister
  end
end
