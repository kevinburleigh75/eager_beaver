require "eager_beaver/version"
require "eager_beaver/method_matcher"

module EagerBeaver

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
