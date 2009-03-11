require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Context do

	it "supports map-like access for data" do
		context = MadderLib::Context.new

		context[:test].should be_nil

		context[:test] ||= :value
		context[:test].should_not be_nil
	end

end
