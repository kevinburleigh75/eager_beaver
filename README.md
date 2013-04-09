# EagerBeaver

## Overview

`EagerBeaver` provides an interface for adding `#method_missing`-related abilities
to a class or module.

## Baseline Implementation

The following is a bare-bones implementation of class which defines `#method_missing`:

```ruby
class NeedsMethods
  def method_missing(method_name, *args, &block)
    if data = NeedsMethods.match_pattern1(method_name)
      puts "pattern1: #{data[:val]}"
    elsif data = NeedsMethods.match_pattern2(method_name)
      puts "pattern2: #{data[:val1]} #{data[:val2]}"
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private=false)
    NeedsMethods.match_pattern1(method_name) || NeedsMethods.match_pattern2(method_name)
  end

  def self.match_pattern1(method_name)
    return {val: $1} if /\Apattern1_(\w+)/ =~ method_name
  end

  def self.match_pattern2(method_name)
    return {val1: $1, val2: $2} if /\Apattern2_(\w+)_(\w+)/ =~ method_name
  end
end

nm1 = NeedsMethods.new
puts "#{nm1.methods.grep /pattern/}"
# => []                                     ## overriding #method_missing doesn't actually add methods
puts "#{nm1.respond_to? :pattern1_match}"
# => true                                   ## #respond_to_missing? in action!
puts "#{nm1.method :pattern1_match}"
# => #<Method: NeedsMethods#pattern1_match> ## #respond_to_missing? in action!
nm1.pattern1_match
# => pattern1: match

nm2 = NeedsMethods.new
puts "#{nm2.methods.grep /pattern/}"
# => []                                     ## missing method was NOT added!
nm2.pattern1_match
# => pattern1: match
nm2.pattern2_another_match
# => pattern2: another match
puts "#{nm1.methods.grep /pattern/}"
# => []                                     ## missing methods were NOT added!
puts "#{nm2.methods.grep /pattern/}"
# => []                                     ## missing methods were NOT added!

nm.blah
# => undefined method `blah' for #<NeedsMethods:0x007fb37b086548> (NoMethodError)
```

## Downsides to the Baseline Implementation

### It's easy to forget something

Changes to `#method_missing` should be accompanied by corresponding changes to `#respond_to_missing?`,
which allows instances of a class to correcly respond to `#respond_to?` and `#method` calls.  It's
easy to overlook this detail since it's likely not the primary focus of adding handlers to
`#method_missing`.

It's also easy to forget the call to `super` when no pattern match is found - in which case all
unmatched method patterns are silently handled!

### Extension requires changes in multiple places

To add handling of another method pattern, the following changes need to be made:
- addition of another `elsif` block in `#method_missing`
- addition of another `||`-ed value in `#respond_to_missing?`
- addition of another pattern-matching class method

### Large method size and method proliferation

As more and more method patterns are added, `#method_missing` and `#respond_to_missing?` will grow
endlessly, as will the number of pattern-matching class methods.

### Tight coupling

Pattern-matching class methods and their corresponding `elsif` blocks in `#method_missing` are
tightly coupled, despite their spatial separation in the code.

The shared code in `#method_missing` and `#respond_to_missing?` means that changes to one pattern
handler can break another if not done properly.

### Handled methods are not added to the class

Each time a matched method is called, the entire `#method_missing` infrastructure is executed.

### Dynamic updates

The baseline implementation assumes that all method patterns should be handled at all times,
which is not always the case.  Sometimes the matched patterns are derived from data not
available to the class until the code is executing.  Correctly redefining (or perpetually
re-aliasing) `#method_missing` and `#respond_to_missing?` can get tricky fast.

## Correcting the Downsides

Most of the downsides to the baseline implementation can be solved by adding an array
of `MethodHandler`s to the class.  Each `MethodHandler` has two parts: one which checks
if the missing method should be handled, and one which does the work.  `#method_missing`
and `#respond_to_missing?` could then be rewritten to iterate over the `MethodHandler`
array and act accordingly.

`EagerBeaver` does this (essentially) but goes one step further: it actually adds the
missing method to the including class and invokes it so that future calls to that
method won't need to invoke the `#method_missing` infrastructure.

## Key Features

- Method matchers can be added dynamically and independently, reducing the risk
  of accidentally altering or removing previously-added functionality.
- Matched methods are automatically reflected in calls to `#respond_to?` and
  `#method`.
- Matched methods are automatically added to the including class/module and
  invoked.  Subsequent calls won't trigger `#method_missing`.
- When a method cannot be matched, `super`'s `#method_missing` is automatically
  invoked.

## Installation

Add this line to your application's Gemfile:

    gem 'eager_beaver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eager_beaver

## Usage

### Inclusion

Any class or module which includes `EagerBeaver` will gain the `add_method_handler`
pseudo-keyword, which [indirectly] yields a `MethodHandler` to the given block:

```ruby
require 'eager_beaver'

class NeedsMethods
  include EagerBeaver

  add_method_handler do |mh|
    ...
  end
end
```

In this case, the resulting `MethodHandler` is added to the end of a `MethodHandler` list
associated with `NeedsMethods`.

Each `MethodHandler` needs two things: a lambda for matching missing method names
and a lambda for handling any method names it matches:

```ruby
  add_method_handler do |mh|
    mh.match  = lambda { ... }
    mh.handle = lambda { ... }
  end
end
```

### Matching

The `match` lambda should return a true value if the missing method name is one
can be handled by the `MethodHandler`.  The following example will match
missing methods of the form `#pattern1_<data>`:

```ruby
    mh.match = lambda {
      context.data = $1 if /\Apattern1_(\w+)/ =~ context.missing_method_name
    }
```

### Context

As the example shows, each `MethodMatcher` contains a `context` which provides:

- the name of the missing method (`context.missing_method_name`)
- the original method receiver instance (`context.original_receiver`)
- a place to stash information (dynamically-generated accessors `context.<attr_name>` and `context.<attr_name>=`)

This `context` is shared between the `match` and `handle` lambdas, and
is reset between uses of each `MethodMatcher`.

### Handling

The `handle` lambda should return a string which will create the
missing method in `NeedsMethods`:

```ruby
    mh.handle = lambda {
      %Q{ def #{context.missing_method_name}
            puts "pattern1: #{context.data}"
          end }
    }
```

As the example shows, it is perfectly reasonable to take advantage of work done
by the `match` lambda (in this case, the parsing of `<data>`).

After the generated code is inserted into `NeedsMethods`, the missing method 
call is resent to the original receiver.

### Complete Example

The following is the baseline implementation above using `EagerBeaver`:

```ruby
require 'eager_beaver'

class NeedsMethods
  include EagerBeaver

  add_method_handler do |mh|
    mh.match = lambda {
      context.data = $1 if /\Apattern1_(\w+)/ =~ context.missing_method_name
    }
    mh.handle = lambda {
      %Q{ def #{context.missing_method_name}
            puts "pattern1: #{context.data}"
          end }
    }
  end

  add_method_handler do |mh|
    mh.match = lambda {
      context.data = {val1: $1, val2: $2} if /\Apattern2_(\w+)_(\w+)/ =~ context.missing_method_name
    }
    mh.handle = lambda {
      %Q{ def #{context.missing_method_name}
            puts "pattern2: #{context.data[:val1]} #{context.data[:val2]}"
          end }
    }
  end
end

nm1 = NeedsMethods.new

puts "#{nm1.methods.grep /pattern/}"
# => []                                     ## overriding #method_missing doesn't actually add methods
puts "#{nm1.respond_to? :pattern1_match}"
# => true                                   ## #respond_to_missing? in action!
puts "#{nm1.method :pattern1_match}"
# => #<Method: NeedsMethods#pattern1_match> ## #respond_to_missing? in action!
nm1.pattern1_match
# => pattern1: match

nm2 = NeedsMethods.new

puts "#{nm2.methods.grep /pattern/}"
# => [:pattern1_match]                      ## missing method added to NeedsMethods!
nm2.pattern1_match
# => pattern1: match                        ## no call to #method_missing
nm2.pattern2_another_match
# => pattern2: another match
puts "#{nm1.methods.grep /pattern/}"
# => [:pattern1_match, :pattern2_another_match]
puts "#{nm2.methods.grep /pattern/}"
# => [:pattern1_match, :pattern2_another_match]

nm2.blah
# => undefined method `blah' for #<NeedsMethods:0x007fefac1a8080> (NoMethodError)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Comhit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
