require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Phrase do
	it "can convert phrase results into words" do
		words = ['one', :two, lambda { 'three' }].collect do |value|
			SentenceBuilder::Phrase.wordify(value)
		end
		words.should eql(%w{ one two three })
	end
end
