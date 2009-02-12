require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "to Generator, Array, etc" do
	WORDS = %w{ one two three }
	
	it "converts to a Generator" do
		gen = (sentence_builder do
			WORDS.each {|word| say word }
		end).to_gen
		
		words = []
		words << gen.next while gen.next?
		words.should eql(WORDS)
	end

	it "converts to a Generator" do
		gen = (sentence_builder do
			WORDS.each {|word| say word }
		end).to_gen
		
		words = []
		words << gen.next while gen.next?
		words.should eql(WORDS)
	end

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
		@builder.to_s("\n");
	end
end
