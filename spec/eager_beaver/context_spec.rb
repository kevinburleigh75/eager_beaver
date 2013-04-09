require 'spec_helper'

describe "EagerBeaver matcher context" do

  describe "#missing_method_name" do
    it "provides the name of the missing method" do
      klass = Class.new do
        include EagerBeaver

        add_method_matcher do |mm|
          mm.matcher = lambda {
            raise context.missing_method_name \
              unless context.missing_method_name == "aaa"
            /\Aaaa\z/ =~ context.missing_method_name 
          }
          mm.new_method_code = lambda {
            raise context.missing_method_name \
              unless context.missing_method_name == "aaa"
            %Q{
              def #{context.missing_method_name}
              end
            }
          }
        end
      end
      expect{ klass.new.aaa }.to_not raise_exception
    end
  end

  describe "#original_receiver" do
    it "provides the orignal method receiver" do
      klass = Class.new do
        include EagerBeaver

        add_method_matcher do |mm|
          mm.matcher = lambda {
            /\Aaaa\z/ =~ context.missing_method_name
          }
          mm.new_method_code = lambda {
            %Q{
              def #{context.missing_method_name}
                #{context.original_receiver.__id__}
              end
            }
          }
        end
      end

      instance = klass.new
      instance.aaa.should equal instance.__id__
    end
  end

  describe "#<attr_name> and #<attr_name>=" do
    it "provide a way to pass data between method matching and code generation" do
      klass = Class.new do
        include EagerBeaver

        add_method_matcher do |mm|
          mm.matcher = lambda {
            context.my_data = "hello"
            /\Aaaa\z/ =~ context.missing_method_name
          }
          mm.new_method_code = lambda {
            %Q{
              def #{context.missing_method_name}
                "#{context.my_data}"
              end
            }
          }
        end
      end

      klass.new.aaa.should == "hello"
    end
  end

end
