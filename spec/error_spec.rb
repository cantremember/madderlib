require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Error do
	it "takes a simple message" do
		e = nil
		message = 'message'

		lambda { raise MadderLib::Error, message }.should raise_error {|error| e = error }
		e.message.should eql(message)
		e.cause.should be_nil
	end

	it "takes a cause, sans message" do
		e = nil
		cause = Exception.new('cause')

		lambda { raise MadderLib::Error.new(cause) }.should raise_error {|error| e = error }
		e.message.should eql('cause')
		e.cause.should equal(cause)
	end

	it "takes both a cause and message" do
		e = nil
		message = 'message'
		cause = Exception.new('cause')

		lambda { raise MadderLib::Error.new(message, cause) }.should raise_error {|error| e = error }
		e.message.should eql(message)
		e.cause.should equal(cause)
	end
end
