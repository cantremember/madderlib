require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "to Generator, Array, etc" do
	before(:each) do
		@builder = SentenceBuilder::Builder.new
	end



	it "converts to a Generator" do
		#	!!!		@builder.to_gen	end

	it "converts to an Array" do
		#	!!!
		@builder.to_a
	end

	it "converts to a String" do
		#	!!!
		@builder.to_s
	end

	it "converts to a String, with separator" do
		#	!!!
		@builder.to_s("\n")
	end
end
