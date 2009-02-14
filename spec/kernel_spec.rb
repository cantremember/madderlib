require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::KernelMethods do
	after(:each) do
		#	complete the current grammar
		#	so that the next test isn't so limited
		madderlib_grammar.complete	end



	it "madderlib requires a block" do		lambda { madderlib }.should raise_error(MadderLib::Error)
	end

	it "provides access to a Builder" do
		#	empty
		builder = madderlib { }

		builder.should_not be_nil
		builder.id.should be_nil
		builder.should be_a(MadderLib::Builder)
		builder.phrases.should have(0).phrases

		#	id only
		builder = madderlib(:id) { }

		builder.should_not be_nil
		builder.id.should equal(:id)
		builder.should be_a(MadderLib::Builder)
		builder.phrases.should have(0).phrases
	end

	it "provides a new Builder each time" do
		builder = madderlib { }
		madderlib { }.should_not equal(builder)	end


	it "provides access to a Grammar" do
		grammar = madderlib_grammar

		#	empty
		grammar.should_not be_nil
		grammar.should be_a(MadderLib::Grammar)
		grammar.should have(0).builders
		grammar.builder_map.should have(0).builders
	end

	it "provides the same Grammar, until completed" do
		#	same
		grammar = madderlib_grammar
		madderlib_grammar.should equal(grammar)

		#	different
		grammar.complete
		madderlib_grammar.should_not equal(grammar)
	end
end
