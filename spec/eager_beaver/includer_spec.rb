require 'spec_helper'

describe "EagerBeaver includer" do

  describe "added methods" do

    before :each do
      @klass = Class.new do
        include EagerBeaver
      end
    end

    it "has #add_method_matcher" do
      expect(@klass.methods).to include :add_method_matcher
    end

    it "has #method_matchers" do
      expect(@klass.methods).to include :method_matchers
    end

  end

  describe "#add_method_matcher" do

    it "registers a new method matcher" do
      klass = Class.new do
        include EagerBeaver

        add_method_matcher do |mm|
          mm.matcher = lambda { true }
          mm.new_method_code = lambda {
            return %Q{
              def #{context.missing_method_name}
              end
            }
          }
        end
      end

      klass.method_matchers.size.should == 1
    end

  end

end
