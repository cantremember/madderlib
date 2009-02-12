require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "to Generator, Array, etc" do
	WORDS = ['one', 'two', 'three']



	it "converts to a Generator" do
		gen = (sentence_builder do
			WORDS.each {|word| say word }
		end).to_gen

		words = []
		words << gen.next while gen.next?
		words.should eql(WORDS)
	end

	it "converts to an Array" do
		array = (sentence_builder do
			WORDS.each {|word| say word }
		end).to_a

		array.should eql(WORDS)
	end

	it "converts to a String" do
		s = (sentence_builder do
			WORDS.each {|word| say word }
		end).to_s

		#	default separator
		s.should eql(WORDS.join(' '))
	end

	it "converts to a String, with separator" do
		s = (sentence_builder do
			WORDS.each {|word| say word }
		end).to_s("\t")

		#	explicit separator
		s.should eql(WORDS.join("\t"))
	end
end
