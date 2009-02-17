require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Conditional::Helper do

	it "a TestBlock fails with invalid arguments" do
		#	arg or block, not both
		lambda {
			MadderLib::Conditional::Helper::TestBlock.new(1) {|count| count < 1 }
		}.should raise_error MadderLib::Error

		#	unsupported
		lambda {
			MadderLib::Conditional::Helper::TestBlock.new(:symbol)
		}.should raise_error MadderLib::Error
	end

	it "a TestBlock with a block" do
		tester = MadderLib::Conditional::Helper::TestBlock.new {|count| count < 1 }

		built = tester.block

		built.call(0).should be_true		built.call(1).should_not be_true

		tester.invoke(0, :ignore).should be_true
		tester.invoke(1, :ignore).should_not be_true
	end

	it "a TestBlock with a fixed limit" do
		tester = MadderLib::Conditional::Helper::TestBlock.new(2)

		built = tester.block

		built.call(1).should be_true
		built.call(2).should_not be_true

		tester.invoke(1, :ignore).should be_true
		tester.invoke(2, :ignore).should_not be_true
	end

	it "a TestBlock with a Range" do
		tester = MadderLib::Conditional::Helper::TestBlock.new(2, 4)

		pound_on do
			built = tester.block

			built.call(1).should be_true
			built.call(4).should_not be_true
		end

		tester.invoke(1, :ignore).should be_true
		tester.invoke(4, :ignore).should_not be_true

		tester = MadderLib::Conditional::Helper::TestBlock.new(Range.new(3, 5))

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(5).should_not be_true
		end

		tester.invoke(2, :ignore).should be_true
		tester.invoke(5, :ignore).should_not be_true
	end



	it "a TestBlock in minutes" do
		tester = MadderLib::Conditional::Helper::TestBlock.new(1, :minute)

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(3).should_not be_true
		end

		tester = MadderLib::Conditional::Helper::TestBlock.new(1, 2, :minute)

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(6).should_not be_true
		end
	end



	it "can convert a TestBlock criterion into an integer" do
		context = MadderLib::Context::EMPTY

		tester = MadderLib::Conditional::Helper::TestBlock.new(1)
		tester.to_i(context).should eql(1)

		tester = MadderLib::Conditional::Helper::TestBlock.new(1, 2)
		tester.to_i(context).should eql(2)

		tester = MadderLib::Conditional::Helper::TestBlock.new(Range.new(3, 4))
		tester.to_i(context).should eql(4)

		tester = MadderLib::Conditional::Helper::TestBlock.new { 2 + 2 }
		tester.to_i(context).should eql(4)

		context.data[:value] = 5
		tester = MadderLib::Conditional::Helper::TestBlock.new {|context| context.data[:value] }
		tester.to_i(context).should eql(5)
	end

	it "invokes the contained block, or one explicitly provided" do
		#	arity < 1
		tester = MadderLib::Conditional::Helper::TestBlock.new { 2 }
		tester.invoke.should eql(2)
		tester.invoke { 0 }.should eql(0)

		#	arity = 1
		tester = MadderLib::Conditional::Helper::TestBlock.new {|value| value + 1 }
		tester.invoke(1).should eql(2)
		tester.invoke(1) {|value| value - 1 }.should eql(0)

		#	arity = 2, discard ignored
		tester = MadderLib::Conditional::Helper::TestBlock.new {|a, b| a + b }
		tester.invoke(1, 1, :ignored).should eql(2)
		tester.invoke(1, 1, :ignored) {|a, b| a - b }.should eql(0)
	end

end
