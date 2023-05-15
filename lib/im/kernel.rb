# frozen_string_literal: true

module Kernel
  module_function

  alias_method :im_original_require, :require
  class << self
    alias_method :im_original_require, :require
  end

  # @sig (String) -> true | false
  def require(path)
    filetype, feature_path = $:.resolve_feature_path(path)

    if (loader = Im::Registry.loader_for(path)) ||
        ((loader = Im::Registry.loader_for(feature_path)) && (path = feature_path))
      if :rb == filetype
        if loaded = !$LOADED_FEATURES.include?(feature_path)
          $LOADED_FEATURES << feature_path
          begin
            if loader.root == Object
              load path
            else
              load path, loader.root
            end
          rescue => e
            $LOADED_FEATURES.delete(feature_path)
            raise e
          end
          loader.on_file_autoloaded(path)
        end
        loaded
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
