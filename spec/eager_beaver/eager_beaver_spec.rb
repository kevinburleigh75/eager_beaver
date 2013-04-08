require 'spec_helper'

describe EagerBeaver do

  describe ".included" do

    before :each do
      @klass = Class.new do
        include EagerBeaver
      end
    end

    it "adds Includer.add_method_matcher" do
      expect(@klass.methods).to include :add_method_matcher
    end

    it "adds Includer.method_matchers" do
      expect(@klass.methods).to include :method_matchers
    end

    it "adds Includer.context" do
      expect(@klass.methods).to include :context
    end

    it "adds Includer.context=" do
      expect(@klass.methods).to include :context=
    end

    it "adds Includer#method_missing" do
      expect(@klass.instance_methods(:false)).to include :method_missing
    end

    it "adds Includer#respond_to_missing?" do
      expect(@klass.instance_methods(:false)).to include :respond_to_missing?
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

  describe "#method_missing" do

    context "method matching" do

      it "invokes the first matching matcher" do
        klass = Class.new do
          include EagerBeaver

          add_method_matcher do |mm|
            mm.matcher = lambda { /\Aaaa\z/ =~ context.missing_method_name }
            mm.new_method_code = lambda {
              %Q{
                def #{context.missing_method_name}
                  1
                end
              }
            }
          end

          add_method_matcher do |mm|
            mm.matcher = lambda { /\Abbb\z/ =~ context.missing_method_name }
            mm.new_method_code = lambda {
              %Q{
                def #{context.missing_method_name}
                  2
                end
              }
            }
          end

          add_method_matcher do |mm|
            mm.matcher = lambda { /\Abbb\z/ =~ context.missing_method_name }
            mm.new_method_code = lambda {
              %Q{
                def #{context.missing_method_name}
                  3
                end
              }
            }
          end
        end

        klass.new.bbb.should == 2
      end

      it "calls super #method_missing if no matcher matches" do
        klass1 = Class.new do
          def method_missing(method_name, *args, &block)
            10
          end
        end

        klass2 = Class.new(klass1) do
          include EagerBeaver

          add_method_matcher do |mm|
            mm.matcher = lambda { /\Aaaa\z/ =~ context.missing_method_name }
            mm.new_method_code = lambda {
              %Q{
                def #{context.missing_method_name}
                  1
                end
              }
            }
          end
        end

        klass2.new.bbb.should == 10
      end

    end

  end

end
