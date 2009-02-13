require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Instruction do

	it "can convert phrase results into words" do
		words = ['one', :two, lambda { 3 }].collect do |value|
			SentenceBuilder::Instruction.wordify(value, SentenceBuilder::Context::EMPTY)
		end

		words.should eql(%w{ one two 3 })

		builder = sentence_builder do
			say 'one'
			say :two
			say { 3 }
		end
		builder.to_words.should eql(%w{ one two 3 })

		words =  SentenceBuilder::Instruction.wordify(builder, SentenceBuilder::Context::EMPTY)
		words.should have(3).words
		words.should eql(%w{ one two 3 })
	end

end
