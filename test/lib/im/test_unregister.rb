# frozen_string_literal: true

require "test_helper"

class TestUnregister < LoaderTest
  test "unregister removes the loader from internal state" do
    loader1 = Im::Loader.new
    registry = Im::Registry
    registry.register_loader(loader1)
    registry.gem_loaders_by_root_file["dummy1"] = loader1
    registry.register_autoload(loader1, "dummy1")
    registry.register_inception("dummy1", "dummy1", loader1)
    Im::ExplicitNamespace.__register("dummy1", "dummyname1", loader1)

    loader2 = Im::Loader.new
    registry = Im::Registry
    registry.register_loader(loader2)
    registry.gem_loaders_by_root_file["dummy2"] = loader2
    registry.register_autoload(loader2, "dummy2")
    registry.register_inception("dummy2", "dummy2", loader2)
    Im::ExplicitNamespace.__register("dummy2", "dummyname2", loader2)

    loader1.unregister

    assert !registry.loaders.include?(loader1)
    assert !registry.gem_loaders_by_root_file.values.include?(loader1)
    assert !registry.autoloads.values.include?(loader1)
    assert !registry.inceptions.values.any? {|_, l| l == loader1}
    assert Im::ExplicitNamespace.send(:cpaths).values.none? { |_, l| loader1 == l }

    assert registry.loaders.include?(loader2)
    assert registry.gem_loaders_by_root_file.values.include?(loader2)
    assert registry.autoloads.values.include?(loader2)
    assert registry.inceptions.values.any? {|_, l| l == loader2}
    assert Im::ExplicitNamespace.send(:cpaths).values.any? { |_, l| loader2 == l }
  end

  test 'with_loader yields and unregisters' do
    loader = Im::Loader.new
    unregister_was_called = false
    loader.define_singleton_method(:unregister) { unregister_was_called = true }

    Im::Loader.stub :new, loader do
      Im.with_loader do |l|
        assert_same loader, l
      end
    end

    assert unregister_was_called
  end

  test 'with_loader yields and unregisters, even if an exception happens' do
    loader = Im::Loader.new
    unregister_was_called = false
    loader.define_singleton_method(:unregister) { unregister_was_called = true }

    Im::Loader.stub :new, loader do
      Im.with_loader { raise } rescue nil
    end

    assert unregister_was_called
  end
end
