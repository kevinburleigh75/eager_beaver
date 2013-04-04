module EagerBeaver

  class MethodMatcher

    attr_accessor :original_caller
    attr_accessor :matcher
    attr_accessor :new_method
    attr_accessor :new_method_code_maker
    attr_accessor :missing_method_name

    def initialize(block)
      block.call(self)

      raise ArgumentError, "matcher Proc must be given" \
        if matcher.nil?
      raise ArgumentError, "exactly one of new_method or new_method_code_maker Proc must be given" \
        if (new_method && new_method_code_maker) || (new_method.nil? && new_method_code_maker.nil?)

      self
    end

    def match?(method_name)
      self.missing_method_name = method_name.to_s
      self.instance_eval &matcher
    end
  end

end