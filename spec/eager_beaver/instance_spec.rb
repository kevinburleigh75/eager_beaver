require 'spec_helper'

describe "instance of EagerBeaver includer" do

  before :each do
    @klass = Class.new do
      include EagerBeaver
    end
  end

  it "has #method_missing" do
    expect(@klass.instance_methods(:false)).to include :method_missing
  end

  it "has #respond_to_missing?" do
    expect(@klass.instance_methods(:false)).to include :respond_to_missing?
  end

  describe "#respond_to?" do

    before :each do
      klass = Class.new do
        include EagerBeaver

        add_method_handler do |mh|
          mh.match = lambda { /\Aaaa_\w+\z/ =~ context.missing_method_name }
          mh.handle = lambda {
            %Q{
              def #{context.missing_method_name}
              end
            }
          }
        end
      end
      @instance = klass.new
    end

    it "returns true for matched method names" do
      expect(@instance.respond_to? :aaa_1).to be_true
      expect(@instance.respond_to? :aaa_2).to be_true
    end

    it "returns false for unmatched method names" do
      expect(@instance.respond_to? :bbb_1).to be_false
      expect(@instance.respond_to? :bbb_2).to be_false
    end

  end

  describe "#method" do

    before :each do
      klass = Class.new do
        include EagerBeaver

        add_method_handler do |mh|
          mh.match = lambda { /\Aaaa_\w+\z/ =~ context.missing_method_name }
          mh.handle = lambda {
            %Q{
              def #{context.missing_method_name}
              end
            }
          }
        end
      end
      @instance = klass.new
    end

    it "returns a Method for matched method names" do
      expect{ @instance.method :aaa_1}.to_not raise_error
      expect{ @instance.method :aaa_2}.to_not raise_error
    end

    it "returns nil for unmatched method names" do
      expect{ @instance.method :bbb_1 }.to raise_error
    end

  end

  describe "#method_missing" do

    it "invokes the first matching matcher" do
      klass = Class.new do
        include EagerBeaver

        add_method_handler do |mh|
          mh.match = lambda { /\Aaaa\z/ =~ context.missing_method_name }
          mh.handle = lambda {
            %Q{
              def #{context.missing_method_name}
                1
              end
            }
          }
        end

        add_method_handler do |mh|
          mh.match = lambda { /\Abbb\z/ =~ context.missing_method_name }
          mh.handle = lambda {
            %Q{
              def #{context.missing_method_name}
                2
              end
            }
          }
        end

        add_method_handler do |mh|
          mh.match = lambda { /\Abbb\z/ =~ context.missing_method_name }
          mh.handle = lambda {
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

        add_method_handler do |mh|
          mh.match = lambda { /\Aaaa\z/ =~ context.missing_method_name }
          mh.handle = lambda {
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