require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::KernelMethods do
	after(:each) do
		#	complete the current grammar
		#	so that the next test isn't so limited
		sentence_grammar.complete	end



	it "sentence_builder requires a block" do		lambda { sentence_builder }.should raise_error(SentenceBuilder::Error)
	end

	it "provides access to a Builder" do
		#	empty
		builder = sentence_builder { }

		builder.should_not be_nil
		builder.id.should be_nil
		builder.should be_a(SentenceBuilder::Builder)
		builder.phrases.should have(0).phrases

		#	id only
		builder = sentence_builder(:id) { }

		builder.should_not be_nil
		builder.id.should equal(:id)
		builder.should be_a(SentenceBuilder::Builder)
		builder.phrases.should have(0).phrases
	end

	it "provides a new Builder each time" do
		builder = sentence_builder { }
		sentence_builder { }.should_not equal(builder)	end


	it "provides access to a Grammar" do
		grammar = sentence_grammar

		#	empty
		grammar.should_not be_nil
		grammar.should be_a(SentenceBuilder::Grammar)
		grammar.should have(0).builders
		grammar.builder_map.should have(0).builders
	end

	it "provides the same Grammar, until completed" do
		#	same
		grammar = sentence_grammar
		sentence_grammar.should equal(grammar)

		#	different
		grammar.complete
		sentence_grammar.should_not equal(grammar)
	end
end
