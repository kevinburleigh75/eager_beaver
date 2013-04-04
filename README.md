# EagerBeaver

Facilitates method_missing, respond_to_missing?, and method-generation activities
by providing a simple interface for adding method generators.  All related
activities, such as registering with #method_missing and #respond_to_missing?
are handled automatically.  Facilitates method name pattern-specific method
generation as well.  Generated methods are added to the missing method receiver.

## Installation

Add this line to your application's Gemfile:

    gem 'eager_beaver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eager_beaver

## Usage

```ruby
require 'eager_beaver'

class NeedsMethods
  include EagerBeaver

  add_method_matcher do |mm|
    mm.matcher = Proc.new do
      /\Amake_(\w+)\z/ =~ missing_method_name
      @attr_name = Regexp.last_match ? Regexp.last_match[1] : nil
      Regexp.last_match
    end
    mm.new_method_code_maker = Proc.new do
      %Q{
        def #{missing_method_name}(arg)
          puts "#{@attr_name} \#{arg}"
        end
      }
    end
  end
end

nm = NeedsMethods.new

nm.make_thingy(10)    # thingy 10
nm.make_widget("hi")  # widget hi
nm.oh_no!             # (NoMethodError)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
