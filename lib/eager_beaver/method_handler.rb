module EagerBeaver

  class MethodHandler

    attr_accessor :original_receiver
    attr_accessor :missing_method_name
    attr_accessor :match
    attr_accessor :handle

    def initialize(&block)
      block.call(self)

      raise "match must be given" \
        if match.nil?
      raise "match must be a lambda" \
        unless match.lambda?

      raise "handle must be given" \
        if handle.nil?
      raise "handle must be a lambda" \
        unless handle.lambda?

      self
    end

    def handles?(method_name)
      self.missing_method_name = method_name.to_s
      return evaluate(match)
    end

    def evaluate(inner)
      outer = lambda { |*args|
        args.shift
        inner.call(*args)
      }
      self.instance_eval &outer
    end

    def method_missing(method_name, *args, &block)
      if /\A(?<attr_name>[a-zA-Z]\w*)=?\z/ =~ method_name
        code = %Q{
          attr_accessor :#{attr_name}
        }
        self.singleton_class.instance_eval code, __FILE__, __LINE__ + 1
        return self.send(method_name, *args, &block)
      end
      super
    end

  end

end