# Im

[![Gem Version](https://badge.fury.io/rb/im.svg)][gem]
[![Build Status](https://github.com/shioyama/im/actions/workflows/ci.yml/badge.svg)][actions]

[gem]: https://rubygems.org/gems/im
[actions]: https://github.com/shioyama/im/actions

<!-- TOC -->

- [Introduction](#introduction)
- [Synopsis](#synopsis)
- [File structure](#file-structure)
  - [File paths match constant paths under loader](#file-paths-match-constant-paths-under-loader)
  - [Root directories](#root-directories)
  - [Relative and absolute cpaths](#relative-and-absolute-cpaths)
- [Usage](#usage)
- [Motivation](#motivation)
- [License](#license)

<!-- /TOC -->

<a id="markdown-introduction" name="introduction"></a>
## Introduction

Im is a thread-safe code loader for anonymous-rooted namespaces in Ruby. It
allows you to share any nested, autoloaded set of code without polluting or in
any way touching the global namespace.

To do this, Im leverages code autoloading, Zeitwerk conventions around file
structure and naming, and two features added in Ruby 3.2: `Kernel#load`
with a module argument[^1] and `Module#const_added`[^2]. Since these Ruby
features are essential to its design, it cannot be used with earlier versions
of Ruby.

Im started its life as a fork of Zeitwerk and has a very similar interface. The
gem strives to follow the Zeitwerk pattern as much as possible. Im and Zeitwerk
can be used alongside each other provided there is no overlap between file
paths managed by each gem.

Im is in active development and should be considered experimental until the
eventual release of version 1.0. Versions 0.1.6 and earlier of the gem were
part of a different experiment and are unrelated to the current gem.

<a id="markdown-synopsis" name="synopsis"></a>
## Synopsis

Im follows an interface that is in most respects identical to Zeitwerk.
The central difference is that whereas Zeitwerk loads constants into the global
namespace (rooted in `Object`), Im loads them into anonymous namespaces rooted
on the loader itself. Loaders in Im are a subclass of the `Module` class, and
thus each one can define its own namespace. Since there can be arbitrarily many
loaders, there can also be arbitrarily many autoloaded namespaces.

Im's gem interface looks like this:

```ruby
# lib/my_gem.rb (main file)

require "im"
loader = Im::Loader.for_gem
loader.setup # ready!

module loader::MyGem
  # ...
end

loader.eager_load # optionally
```

The generic interface is likewise identical to Zeitwerk's:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.setup # ready!
```

Other than gem names, the only difference here is in the definition of `MyGem`
under the loader namespace in the gem code. Unlike Zeitwerk, with Im the gem
namespace is not defined at toplevel:

```ruby
Object.const_defined?(:MyGem)
# => false
```

In order to prevent leakage, the gem's entrypoint, in this case
`lib/my_gem.rb`), must not define anything at toplevel, hence the use of
`module loader::MyGem`.

Once the entrypoint has been required, all constants defined within the gem's
file structure are autoloadable from the loader itself:

```ruby
# lib/my_gem/foo.rb

module MyGem
  class Foo
    def hello_world
      "Hello World!"
    end
  end
end
```

```ruby
foo = loader::MyGem::Foo
# loads `Foo` from lib/my_gem/foo.rb

foo.new.hello_world
# "Hello World!"
```

Constants under the loader can be given permanent names that are different from
the one defined in the gem itself:

```ruby
Bar = loader::MyGem::Foo
Bar.new.hello_world
# "Hello World!"
```

Since Im uses loaders as its namespace roots, it is important that consumers of
gems have a way to fetch the loader for a given file path.

The loader variable can go out of scope. Like Zeitwerk, Im keeps a registry
with all of them, and so the object won't be garbage collected. For
convenience, Im also provides a method, `Im#import`, to fetch a loader for
a given file path:

```ruby
require "im"
require "my_gem"

extend Im
my_gem = import "my_gem"
#=> loader::MyGem is autoloadable
```

Reloading works like Zeitwerk:

```ruby
loader = Im::Loader.new
loader.push_dir(...)
loader.enable_reloading # you need to opt-in before setup
loader.setup
...
loader.reload
```

You can assign a permanent name to an autoloaded constant, and it will be
reloaded when the loader is reloaded:

```ruby
Foo = loader::Foo
loader.reload # Object::Foo is replaced by an autoload
Foo #=> autoload is triggered, reloading loader::Foo
```

Like Zeitwerk, you can eager-load all the code at once:

```ruby
loader.eager_load
```

Alternatively, you can broadcast `eager_load` to all loader instances:

```ruby
Im::Loader.eager_load_all
```

<a id="markdown-file-structure" name="file-structure"></a>
## File structure

<a id="markdown-the-idea-file-paths-match-constant-paths-under-loader" name="the-idea-file-paths-match-constant-paths-under-loader"></a>
### File paths match constant paths under loader

File structure is identical to Zeitwerk, again with the difference that
constants are loaded from the loader's namespace rather than the root one:

```
lib/my_gem.rb         -> loader::MyGem
lib/my_gem/foo.rb     -> loader::MyGem::Foo
lib/my_gem/bar_baz.rb -> loader::MyGem::BarBaz
lib/my_gem/woo/zoo.rb -> loader::MyGem::Woo::Zoo
```

Im inherits support for collapsing directories and custom inflection, see
Zeitwerk's documentation for details on usage of these features.

<a id="markdown-root-directories" name="root-directories"></a>
### Root directories

Internally, each loader in Im can have one or more _root directories_ from which
it loads code onto itself. Root directories are added to the loader using
`Im::Loader#push_dir`:

```ruby
loader.push_dir("#{__dir__}/models")
loader.push_dir("#{__dir__}/serializers"))
```

Note that concept of a _root namespace_, which Zeitwerk uses to load code
under a given node of the global namespace, is absent in Im. Custom root
namespaces are likewise not supported. These features were removed as they add
complexity for little gain given Im's flexibility to anchor a namespace
anywhere in the global namespace.

<a id="markdown-relative-and-absolute-cpaths" name="relative-and-absolute-cpaths"></a>
### Relative and absolute cpaths

Im uses two types of constant paths: relative and absolute, wherever possible
defaulting to relative ones. A relative cpath is a constant name relative to
the loader in which it was originally defined, regardless of any other names it
was assigned. Whereas Zeitwerk uses absolute cpaths, Im uses relative cpaths for
all external loader APIs (see usage for examples).

To understand these concepts, it is important first to distinguish between two
types of names in Ruby: _temporary names_ and _permanent names_.

A temporary name is a constant name on an anonymous-rooted namespace, for
example a loader:

```ruby
my_gem = import "my_gem"
my_gem::Foo
my_gem::Foo.name
#=> "#<Im::Loader ...>::Foo"
```

Here, the string `"#<Im::Loader ...>::Foo"` is called a temporary name. We can
give this module a permanent name by assigning it to a toplevel constant:

```ruby
Bar = my_gem::Foo
my_gem::Foo.name
#=> "Bar"
```

Now its name is `"Bar"`, and it is near impossible to get back its original
temporary name.

This property of module naming in Ruby is problematic since cpaths are used as
keys in Im's internal registries to index constants and their autoloads, which
is critical for successful autoloading.

To get around this issue, Im tracks all module names and uses relative naming
inside loader code. You can get the name of a module relative to the loader
that loaded it with `Im::Loader#relative_cpath`:

```ruby
my_gem.relative_cpath(my_gem::Foo)
#=> "Foo"
```

Using relative cpaths frees Im from depending on `Module#name` for
registry keys like Zeitwerk does, which does not work with anonymous
namespaces. All public methods in Im that take a `cpath` take the _relative_
cpath, i.e. the cpath relative to the loader as toplevel, regardless of any
toplevel-rooted constant a module may have been assigned to.

<a id="markdown-usage" name="usage"></a>
## Usage

(TODO)

<a id="markdown-motivation" name="motivation"></a>
## Motivation

(TODO)

<a id="markdown-license" name="license"></a>
## License

Released under the MIT License, Copyright (c) 2023 Chris Salzberg and 2019–<i>ω</i> Xavier Noria.

[^1]: https://bugs.ruby-lang.org/issues/6210
[^2]: https://bugs.ruby-lang.org/issues/17881
