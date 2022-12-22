# frozen_string_literal: true

module Kernel
  module_function

  alias_method :im_original_require, :require
  class << self
    alias_method :im_original_require, :require
  end

  # @sig (String) -> true | false
  def require(path)
    if loader = Im::Registry.loader_for(path)
      if path.end_with?(".rb")
        required = im_original_require(path)
        loader.on_file_autoloaded(path) if required
        required
      else
        loader.on_dir_autoloaded(path)
        true
      end
    else
      required = im_original_require(path)
      if required
        abspath = $LOADED_FEATURES.last
        if loader = Im::Registry.loader_for(abspath)
          loader.on_file_autoloaded(abspath)
        end
      end
      required
    end
  end
end
