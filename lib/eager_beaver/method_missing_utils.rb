module MethodMissingUtils

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

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def method_missing(method_name, *args, &block)
    self.class.method_matchers.each do |method_matcher|
      method_matcher.original_caller = self
      if method_matcher.match?(method_name)
        if method_matcher.new_method
          self.class.send(:define_method, method_name, method_matcher.new_method)
        elsif method_matcher.new_method_code_maker
          method_string = method_matcher.instance_eval &method_matcher.new_method_code_maker
          self.class.class_eval method_string, __FILE__, __LINE__ + 1
        end
        return self.send(method_name, *args, &block)
      end
    end
    super
  end

  def respond_to_missing?(method_name, include_private=false)
    self.class.method_matchers.each do |method_matcher|
      return true if method_matcher.match?(method_name)
    end
    super
  end

  module ClassMethods
    def method_matchers
      @method_matchers ||= []
    end

    def add_method_matcher(&block)
      method_matchers << MethodMatcher.new(block)
    end
  end

end
