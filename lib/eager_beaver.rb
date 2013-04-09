require "eager_beaver/version"
require "eager_beaver/method_matcher"

module EagerBeaver

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def method_missing(method_name, *args, &block)
    self.class.method_matchers.each do |method_matcher|
      mm = method_matcher.dup
      self.class.context = mm
      mm.original_receiver = self
      if mm.match?(method_name)
        method_string = mm.evaluate mm.new_method_code_maker
        self.class.class_eval method_string, __FILE__, __LINE__ + 1
        return self.send(method_name, *args, &block)
      end
    end
    super
  end

  def respond_to_missing?(method_name, include_private=false)
    self.class.method_matchers.each do |method_matcher|
      mm = method_matcher.dup
      self.class.context = mm
      mm.original_receiver = self
      return true if mm.match?(method_name)
    end
    super
  end

  module ClassMethods
    def method_matchers
      @method_matchers ||= []
    end

    def add_method_matcher(&block)
      method_matchers << MethodMatcher.new(&block)
    end

    attr_accessor :context
  end

end
