# frozen_string_literal: true

module Im
  # Centralizes the logic for the trace point used to detect the creation of
  # explicit namespaces, needed to descend into matching subdirectories right
  # after the constant has been defined.
  #
  # The implementation assumes an explicit namespace is managed by one loader.
  # Loaders that reopen namespaces owned by other projects are responsible for
  # loading their constant before setup. This is documented.
  module ExplicitNamespace # :nodoc: all
    class << self
      extend Internal

      # Maps constant paths that correspond to explicit namespaces according to
      # the file system, to the loader responsible for them.
      #
      # @sig Hash[String, [String, Im::Loader]]
      attr_reader :cpaths
      private :cpaths

      # @sig Mutex
      attr_reader :mutex
      private :mutex

      # @sig TracePoint
      attr_reader :tracer
      private :tracer

      # Asserts `cpath` corresponds to an explicit namespace for which `loader`
      # is responsible.
      #
      # @sig (String, Im::Loader) -> void
      internal def register(cpath, module_name, loader)
        mutex.synchronize do
          cpaths[cpath] = [module_name, loader]
          # We check enabled? because, looking at the C source code, enabling an
          # enabled tracer does not seem to be a simple no-op.
          tracer.enable unless tracer.enabled?
        end
      end

      # @sig (Im::Loader) -> void
      internal def unregister_loader(loader)
        cpaths.delete_if { |_cpath, (_, l)| l == loader }
        disable_tracer_if_unneeded
      end

      internal def update_cpaths(prefix, pattern, replacement)
        mutex.synchronize do
          cpaths.transform_keys! do |key|
            key.start_with?(prefix) ? key.gsub(pattern, replacement) : key
          end
        end
      end

      # @sig () -> void
      private def disable_tracer_if_unneeded
        mutex.synchronize do
          tracer.disable if cpaths.empty?
        end
      end

      # @sig (TracePoint) -> void
      private def tracepoint_class_callback(event)
        # If the class is a singleton class, we won't do anything with it so we
        # can bail out immediately. This is several orders of magnitude faster
        # than accessing its name.
        return if event.self.singleton_class?

        # It might be tempting to return if name.nil?, to avoid the computation
        # of a hash code and delete call. But Ruby does not trigger the :class
        # event on Class.new or Module.new, so that would incur in an extra call
        # for nothing.
        #
        # On the other hand, if we were called, cpaths is not empty. Otherwise
        # the tracer is disabled. So we do need to go ahead with the hash code
        # computation and delete call.
        module_name, loader = cpaths.delete(real_mod_name(event.self))
        if loader
          loader.on_namespace_loaded(module_name)
          disable_tracer_if_unneeded
        end
      end
    end

    @cpaths = {}
    @mutex  = Mutex.new

    # We go through a method instead of defining a block mainly to have a better
    # label when profiling.
    @tracer = TracePoint.new(:class, &method(:tracepoint_class_callback))
  end
end
