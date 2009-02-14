require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Helper do

	it "a TestBlock fails with invalid arguments" do
		#	arg or block, not both
		lambda {
			SentenceBuilder::Conditional::Helper::TestBlock.new(1) {|count| count < 1 }
		}.should raise_error SentenceBuilder::Error

		#	unsupported
		lambda {
			SentenceBuilder::Conditional::Helper::TestBlock.new(:symbol)
		}.should raise_error SentenceBuilder::Error
	end

	it "a TestBlock with a block" do
		tester = SentenceBuilder::Conditional::Helper::TestBlock.new {|count| count < 1 }

		built = tester.block

		built.call(0).should be_true
	end

	it "a TestBlock with a fixed limit" do
		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(2)

		built = tester.block

		built.call(1).should be_true
		built.call(2).should_not be_true
	end

	it "a TestBlock with a Range" do
		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(2, 4)

		pound_on do
			built = tester.block

			built.call(1).should be_true
			built.call(4).should_not be_true
		end

		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(Range.new(3, 5))

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(5).should_not be_true
		end
	end

	it "a TestBlock in minutes" do
		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(1, :minute)

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(3).should_not be_true
		end

		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(1, 2, :minute)

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(6).should_not be_true
		end
	end

	it "can convert a TestBlock criterion into an integer" do
		context = SentenceBuilder::Context::EMPTY

		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(1)
		tester.to_i(context).should eql(1)

		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(1, 2)
		tester.to_i(context).should eql(2)

		tester = SentenceBuilder::Conditional::Helper::TestBlock.new(Range.new(3, 4))
		tester.to_i(context).should eql(4)

		tester = SentenceBuilder::Conditional::Helper::TestBlock.new { 2 + 2 }
		tester.to_i(context).should eql(4)

		context.data[:value] = 5
		tester = SentenceBuilder::Conditional::Helper::TestBlock.new {|context| context.data[:value] }
		tester.to_i(context).should eql(5)
	end
end