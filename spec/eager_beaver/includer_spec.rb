require 'spec_helper'

describe "EagerBeaver includer" do

  describe "added methods" do

    before :each do
      @klass = Class.new do
        include EagerBeaver
      end
    end

    it "has #add_method_handler" do
      expect(@klass.methods).to include :add_method_handler
    end

    it "has #method_handlers" do
      expect(@klass.methods).to include :method_handlers
    end

  end

  describe "#add_method_handler" do

    it "registers a new method matcher" do
      klass = Class.new do
        include EagerBeaver

        add_method_handler do |mh|
          mh.match  = lambda { true }
          mh.handle = lambda {
            return %Q{
              def #{context.missing_method_name}
              end
            }
          }
        end
      end

      klass.method_handlers.size.should == 1
    end

  end

end
