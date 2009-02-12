require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Helper do

	it "a CountTester fails with invalid arguments" do
		#	arg or block, not both
		lambda {
			SentenceBuilder::Conditional::Helper::CountTester.new(1) {|count| count < 1 }
		}.should raise_error SentenceBuilder::Error

		#	unsupported
		lambda {
			SentenceBuilder::Conditional::Helper::CountTester.new(:symbol)
		}.should raise_error SentenceBuilder::Error
	end

	it "a CountTester with a block" do
		tester = SentenceBuilder::Conditional::Helper::CountTester.new {|count| count < 1 }

		built = tester.block

		built.call(0).should be_true		built.call(1).should_not be_true
	end

	it "a CountTester with a fixed limit" do
		tester = SentenceBuilder::Conditional::Helper::CountTester.new(2)

		built = tester.block

		built.call(1).should be_true
		built.call(2).should_not be_true
	end

	it "a CountTester with a Range" do
		tester = SentenceBuilder::Conditional::Helper::CountTester.new(2, 4)

		pound_on do
			built = tester.block

			built.call(1).should be_true
			built.call(4).should_not be_true
		end

		tester = SentenceBuilder::Conditional::Helper::CountTester.new(Range.new(3, 5))

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(5).should_not be_true
		end
	end

	it "a CountTester in minutes" do
		tester = SentenceBuilder::Conditional::Helper::CountTester.new(1, :minute)

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(3).should_not be_true
		end

		tester = SentenceBuilder::Conditional::Helper::CountTester.new(1, 2, :minute)

		pound_on do
			built = tester.block

			built.call(2).should be_true
			built.call(6).should_not be_true
		end
	end
end
