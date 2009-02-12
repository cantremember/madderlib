require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Phrase do
	it "can convert phrase results into words" do
		context = SentenceBuilder::Context.new(nil)
		words = ['one', :two, lambda { 3 }].collect do |value|
			SentenceBuilder::Instruction.wordify(value, context)
		end

		words.should eql(%w{ one two 3 })
	end
end
