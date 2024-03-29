# frozen_string_literal: true

require "test_helper"

# Rails applications are expected to preload STIs. Using requires is the old
# school way to address this and it is somewhat tricky. Let's have a test to
# make sure the circularity works.
class TestOldSchoolWorkaroundSTI < LoaderTest
  def files
    [
      ["a.rb", <<-EOS],
        class A
          require 'b'
        end
        $test_sti_loaded << 'A'
      EOS
      ["b.rb", <<-EOS],
        class B < A
          require 'c'
        end
        $test_sti_loaded << 'B'
      EOS
      ["c.rb", <<-EOS],
        class C < B
          require 'd1'
          require 'd2'
        end
        $test_sti_loaded << 'C'
      EOS
      ["d1.rb", "class D1 < C; end; $test_sti_loaded << 'D1'"],
      ["d2.rb", "class D2 < C; end; $test_sti_loaded << 'D2'"]
    ]
  end

  def with_setup
    original_verbose = $VERBOSE
    $VERBOSE = nil # To avoid circular require warnings.

    $test_sti_loaded = []

    super(files, load_path: ".") do
      yield
    end
  ensure
    $VERBOSE = original_verbose
  end

  def assert_all_loaded
    assert_equal %w(A B C D1 D2), $test_sti_loaded.sort
  end

  test "loading the root loads everything" do
    with_setup do
      assert loader::A
      assert_all_loaded
    end
  end

  test "loading a root child loads everything" do
    with_setup do
      assert loader::B
      assert_all_loaded
    end
  end

  test "loading an intermediate descendant loads everything" do
    with_setup do
      assert loader::C
      assert_all_loaded
    end
  end

  test "loading a leaf loads everything" do
    with_setup do
      assert loader::D1
      assert_all_loaded
    end
  end
end
