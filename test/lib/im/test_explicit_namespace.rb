# frozen_string_literal: true

require "test_helper"

class TestExplicitNamespace < LoaderTest
  test "explicit namespaces are loaded correctly (directory first, Object)" do
    files = [
      ["hotel.rb", "class Hotel; X = 1; end"],
      ["hotel/pricing.rb", "class Hotel::Pricing; end"]
    ]
    with_setup(files) do
      assert_kind_of Class, loader::Hotel
      assert loader::Hotel::X
      assert loader::Hotel::Pricing
    end
  end

  test "explicit namespaces are loaded correctly (file first, Object)" do
    files = [
      ["rd1/hotel.rb", "class Hotel; X = 1; end"],
      ["rd2/hotel/pricing.rb", "class Hotel::Pricing; end"]
    ]
    with_setup(files) do
      assert_kind_of Class, loader::Hotel
      assert loader::Hotel::X
      assert loader::Hotel::Pricing
    end
  end

  test "explicit namespaces are loaded correctly even if #name is overridden" do
    files = [
      ["hotel.rb", <<~RUBY],
        class Hotel
          def self.name
            "X"
          end
        end
      RUBY
      ["hotel/pricing.rb", "class Hotel::Pricing; end"]
    ]
    with_setup(files) do
      assert loader::Hotel::Pricing
    end
  end

  test "autoloads are set correctly, even if there are autoloads for the same cname in the superclass" do
    files = [
      ["a.rb", "class A; end"],
      ["a/x.rb", "A::X = :A"],
      ["b.rb", "class B < A; end"],
      ["b/x.rb", "B::X = :B"]
    ]
    with_setup(files) do
      assert_kind_of Class, loader::A
      assert_kind_of Class, loader::B
      assert_equal :B, loader::B::X
    end
  end

  test "autoloads are set correctly, even if there are autoloads for the same cname in a module prepended to the superclass" do
    files = [
      ["m/x.rb", "M::X = :M"],
      ["a.rb", "class A; prepend M; end"],
      ["b.rb", "class B < A; end"],
      ["b/x.rb", "B::X = :B"]
    ]
    with_setup(files) do
      assert_kind_of Class, loader::A
      assert_kind_of Class, loader::B
      assert_equal :B, loader::B::X
    end
  end

  test "autoloads are set correctly, even if there are autoloads for the same cname in other ancestors" do
    files = [
      ["m/x.rb", "M::X = :M"],
      ["a.rb", "class A; include M; end"],
      ["b.rb", "class B < A; end"],
      ["b/x.rb", "B::X = :B"]
    ]
    with_setup(files) do
      assert_kind_of Class, loader::A
      assert_kind_of Class, loader::B
      assert_equal :B, loader::B::X
    end
  end

  test "namespace promotion updates the registry" do
    # We use two root directories to make sure the loader visits the implicit
    # rd1/m first, and the explicit rd2/m.rb after it.
    files = [
      ["rd1/m/x.rb", "M::X = true"],
      ["rd2/m.rb", "module M; end"]
    ]
    with_setup(files) do
      assert_nil Im::Registry.loader_for(File.expand_path("rd1/m"))
      assert_same loader, Im::Registry.loader_for(File.expand_path("rd2/m.rb"))
    end
  end

  # As of this writing, a tracer on the :class event does not seem to have any
  # performance penalty in an ordinary code base. But I prefer to precisely
  # control that we use a tracer only if needed in case this issue
  #
  #     https://bugs.ruby-lang.org/issues/14104
  #
  # goes forward.
  def tracer
    Im::ExplicitNamespace.send(:tracer)
  end

  test "the tracer starts disabled" do
    assert !tracer.enabled?
  end

  test "simple autoloading does not enable the tracer" do
    files = [["x.rb", "X = true"]]
    with_setup(files) do
      assert !tracer.enabled?
      assert loader::X
      assert !tracer.enabled?
    end
  end

  test "autovivification does not enable the tracer, one directory" do
    files = [["foo/bar.rb", "module Foo::Bar; end"]]
    with_setup(files) do
      assert !tracer.enabled?
      assert loader::Foo::Bar
      assert !tracer.enabled?
    end
  end

  test "autovivification does not enable the tracer, two directories" do
    files = [
      ["rd1/foo/bar.rb", "module Foo::Bar; end"],
      ["rd2/foo/baz.rb", "module Foo::Baz; end"],
    ]
    with_setup(files) do
      assert !tracer.enabled?
      assert loader::Foo::Bar
      assert !tracer.enabled?
    end
  end

  test "explicit namespaces enable the tracer until loaded" do
    files = [
      ["hotel.rb", "class Hotel; end"],
      ["hotel/pricing.rb", "class Hotel::Pricing; end"]
    ]
    with_setup(files) do
      assert tracer.enabled?
      assert loader::Hotel
      assert !tracer.enabled?
      assert loader::Hotel::Pricing
      assert !tracer.enabled?
    end
  end

  # This is a regression test.
  test "the tracer handles singleton classes" do
    files = [
      ["hotel.rb", <<-EOS],
        class Hotel
          class << self
            def x
              1
            end
          end
        end
      EOS
      ["hotel/pricing.rb", "class Hotel::Pricing; end"],
      ["car.rb", "class Car; end"],
      ["car/pricing.rb", "class Car::Pricing; end"],
    ]
    with_setup(files) do
      assert tracer.enabled?
      assert_equal 1, loader::Hotel.x
      assert tracer.enabled?
    end
  end

  test "non-hashable explicit namespaces are supported" do
    files = [
      ["m.rb", <<~EOS],
        module M
          # This method is overridden with a different arity. Therefore, M is
          # not hashable. See https://github.com/fxn/zeitwerk/issues/188.
          def self.hash(_)
          end
        end
      EOS
      ["m/x.rb", "M::X = true"]
    ]
    with_setup(files) do
      assert loader::M::X
    end
  end
end
