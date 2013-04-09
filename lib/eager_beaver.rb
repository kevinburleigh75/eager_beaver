require "eager_beaver/version"
require "eager_beaver/method_handler"

module EagerBeaver

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def method_missing(method_name, *args, &block)
    self.class.method_handlers.each do |method_handler|
      mh = configure_handler method_handler
      if mh.handles?(method_name)
        method_string = mh.evaluate mh.handle
        self.class.class_eval method_string, __FILE__, __LINE__ + 1
        return self.send(method_name, *args, &block)
      end
    end
    super
  end

  def respond_to_missing?(method_name, include_private=false)
    self.class.method_handlers.each do |method_handler|
      mh = configure_handler method_handler
      return true if mh.handles?(method_name)
    end
    super
  end

  def configure_handler(handler)
    mh = handler.dup
    mh.original_receiver = self
    mh.original_receiver.class.context = mh
  end

  module ClassMethods
    def method_handlers
      @method_handlers ||= []
    end

    def add_method_handler(&block)
      method_handlers << MethodHandler.new(&block)
    end

    attr_accessor :context
  end

end
