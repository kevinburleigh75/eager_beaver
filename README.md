# EagerBeaver

## Overview

`EagerBeaver` provides an interface for adding `#method_missing`-related abilities
to a class or module.

## Key Features

- Method matchers can be added dynamically and cumulatively, reducing the risk
  of accidentally altering or removing previously-added functionality.
- Matched methods are automatically reflected in calls to `#respond_to?` and
  `#method`, DRY-ing up code by centralizing method-matching logic.
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

Any class or module which includes `EagerBeaver` will gain the `add_method_matcher`
pseudo-keyword, which [indirectly] yields an `EagerBeaver::MethodMatcher` to the
given block:

```ruby
require 'eager_beaver'

class NeedsMethods
  include EagerBeaver

  add_method_matcher do |mm|
    ...
  end
end
```

In this case, the resulting `MethodMatcher` is added to the end of a `MethodMatcher` list
associated with `NeedsMethods`.

Each `MethodMatcher` needs two things: a lambda for matching missing method names
and a lambda for creating the code for any method names it matches:

```ruby
  add_method_matcher do |mm|
    mm.match = lambda { ... }
    mm.new_method_code = lambda { ...}
  end
end
```

### Matching

The `match` lambda should return a true value if the missing method name is one
can be handled by the `MethodMatcher`.  The following example will match
missing methods of the form `#make_<attr_name>`:

```ruby
    mm.match = lambda {
      /\Amake_(\w+)\z/ =~ context.missing_method_name
      context.attr_name = Regexp.last_match ? Regexp.last_match[1] : nil
      return Regexp.last_match
    }
```

### Context

As the example shows, each `MethodMatcher` contains a `context` which provides:

- the name of the missing method (`context.missing_method_name`)
- the original method receiver instance (`context.original_receiver`)
- a place to stash information (`context.<attr_name>` and `context.<attr_name>=`)

This `context` is shared between the `match` and `new_method_code` lambdas, and
is reset between uses of each `MethodMatcher`.

### Code Generation

The `new_method_code` lambda should return a string which will create the
missing method in `NeedsMethods`:

```ruby
    mm.new_method_code = lambda {
      code = %Q{
        def #{context.missing_method_name}(arg)
          puts "method \##{context.missing_method_name} has been called"
          puts "\##{context.missing_method_name} was originally called on #{context.original_receiver}"
          puts "#{context.attr_name} was passed from matching to code generation"
          puts "the current call has arguments: \#{arg}"
          return "result = \#{arg}"
        end
      }
      return code
    }
```

As the example shows, it is perfectly reasonable to take advantage of work done
by the `match` lambda (in this case, the parsing of `<attr_name>`).

After the generated code is inserted into `NeedsMethods`, the missing method 
call is resent to the original receiver.

### Complete Example

```ruby
require 'eager_beaver'

class NeedsMethods
  include EagerBeaver

  add_method_matcher do |mm|
    mm.match = lambda {
      /\Amake_(\w+)\z/ =~ context.missing_method_name
      context.attr_name = Regexp.last_match ? Regexp.last_match[1] : nil
      return Regexp.last_match
    }

    mm.new_method_code = lambda {
      code = %Q{
        def #{context.missing_method_name}(arg)
          puts "method \##{context.missing_method_name} has been called"
          puts "\##{context.missing_method_name} was originally called on #{context.original_receiver}"
          puts "#{context.attr_name} was passed from matching to code generation"
          puts "the current call has arguments: \#{arg}"
          return "result = \#{arg}"
        end
      }
      return code
    }
  end
end
```

## Execution

Given the `NeedsMethods` class in the example above, let's work through the
following code:

```ruby
nm1 = NeedsMethods.new
puts nm1.make_thingy(10)
puts nm1.make_widget("hi")

nm2 = NeedsMethods.new
puts nm2.make_thingy(20)
puts nm2.make_widget("hello")

nm2.dont_make_this
```

As instances of `NeedsMethods`, `nm1` and `nm2` will automatically hande
methods of the form `#make_<attr_name>`.

The line:
```ruby
puts nm1.make_thingy(10)
```
will trigger `nm1`'s `#method_missing`, which `NeedsMethods` implements thanks to
`EagerBeaver`.  Each `MethodMatcher` associated with `EagerBeaver` is run against
the method name `make_thingy`, and sure enough one matches.  This causes the
following methods to be inserted to `NeedsMethods`:
```ruby
  def make_thingy(arg)
    puts "method #make_thingy has been called"
    puts "#make_thingy was originally called on #<NeedsMethods:0x007fa1bc17f498>"
    puts "thingy was passed from matching to code generation"
    puts "the current call has arguments: #{arg}"
    return "result = #{arg}"
  end
```
and when `#make_thingy` is resent to `nm1`, the existing method is called and 
outputs:

> method \#make_thingy has been called<br/>
> \#make_thingy was originally called on \#\<NeedsMethods:0x007fa1bc17f498\><br/>
> thingy was passed from matching to code generation<br/>
> the current call has arguments: 10<br/>
> result = 10

Similarly, the line:
```ruby
puts nm1.make_widget("hi")
```
generates the code:
```ruby
  def make_widget(arg)
    puts "method #make_widget has been called"
    puts "#make_widget was originally called on #<NeedsMethods:0x007fa1bc17f498>"
    puts "widget was passed from matching to code generation"
    puts "the current call has arguments: #{arg}"
    return "result = #{arg}"
  end
```
and outputs:
> method \#make_widget has been called<br/>
> \#make_widget was originally called on \#\<NeedsMethods:0x007fa1bc17f498\><br/>
> widget was passed from matching to code generation<br/>
> the current call has arguments: hi<br/>
> result = hi

Note that the following lines do NOT trigger `#method_missing` because both methods
have already been added to `NeedsMethods`:
```ruby
puts nm2.make_thingy(20)
puts nm2.make_widget("hello")
```
This can be seen by examining the identity of the original receiver in the output:

> **method \#make_thingy has been called**<br/>
> **\#make_thingy was originally called on \#\<NeedsMethods:0x007fa1bc17f498\>**<br/>
> **thingy was passed from matching to code generation**<br/>
> the current call has arguments: 20<br/>
> result = 20

> **method \#make_widget has been called**<br/>
> **\#make_widget was originally called on \#\<NeedsMethods:0x007fa1bc17f498\>**<br/>
> **widget was passed from matching to code generation**<br/>
> the current call has arguments: hello<br/>
> result = hello

String substitutions which were part of the generated code body (emphasized)
reflect the circumstances of the first set of method calls, as opposed to 
those which reflect the current call's argument.

Finally, the call:
`nm2.dont_make_this`
will cause `NeedsMethods` to examine all of its `MethodMatcher`s and finally call
`super`'s `#method_missing`.  Because no superclass of `NeedsMethods` handles
`#dont_make_this`, the output is:

> undefined method `dont_make_this' for \#\<NeedsMethods:0x007f8e2b991f90\> (NoMethodError)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
