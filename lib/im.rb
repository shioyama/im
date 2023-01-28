# frozen_string_literal: true

module Im
  require_relative "im/const_path"
  require_relative "im/internal"
  require_relative "im/loader"
  require_relative "im/gem_loader"
  require_relative "im/registry"
  require_relative "im/explicit_namespace"
  require_relative "im/module_const_added"
  require_relative "im/inflector"
  require_relative "im/gem_inflector"
  require_relative "im/kernel"
  require_relative "im/error"
  require_relative "im/version"

  extend Im::ConstPath

  # @sig (String) -> Im::Loader?
  def import(path)
    _, feature_path = $:.resolve_feature_path(path)
    Registry.loader_for(feature_path) if feature_path
  end

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

  extend self
end
