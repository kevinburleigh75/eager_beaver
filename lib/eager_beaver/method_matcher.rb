module EagerBeaver

  class MethodMatcher

    attr_accessor :original_receiver
    attr_accessor :matcher
    attr_accessor :new_method_code_maker
    attr_accessor :missing_method_name

    def initialize(&block)
      block.call(self)

      raise "matcher must be given" \
        if matcher.nil?
      raise "matcher lmust be a lambda" \
        unless matcher.lambda?

      raise "new_method_code_maker must be given" \
        if new_method_code_maker.nil?
      raise "new_method_code_maker must be a lambda" \
        unless new_method_code_maker.lambda?

      self
    end

    def match=(lambda_proc)
      self.matcher = lambda_proc
    end

    def match?(method_name)
      self.missing_method_name = method_name.to_s
      return evaluate(matcher)
    end

    def new_method_code=(lambda_proc)
      self.new_method_code_maker = lambda_proc
    end

    def evaluate(inner)
      outer = lambda { |*args|
        args.shift
        inner.call(*args)
      }
      self.instance_eval &outer
    end

    def method_missing(method_name, *args, &block)
      if /\A(?<attr_name>\w+)=?\z/ =~ method_name
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