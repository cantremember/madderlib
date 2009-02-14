require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Grammar do
	before(:all) do
		@class = SentenceBuilder::Grammar

		#	close any pre-existing grammar
		sentence_grammar.close
	end



	it "get_instance returns a singleton" do
		@class.get_instance.should equal(@class.get_instance)
	end

	it "retains a list of unique Builders, and a map of id'd Builders" do
		grammar = @class.get_instance

		grammar.should have(0).builders
		grammar.builder_map.should have(0).builders

		#	un-id'd
		builder = SentenceBuilder::Builder.new
		grammar << builder

		grammar.should have(1).builders
		grammar.builders.last.should equal(builder)
		grammar.builder_map.should have(0).builders

		#	duplicate
		grammar << builder

		grammar.should have(1).builders
		grammar.builder_map.should have(0).builders

		#	id'd
		builder = SentenceBuilder::Builder.new(:named)
		grammar << builder

		grammar.should have(2).builders
		grammar.builders.last.should equal(builder)
		grammar.builder_map.should have(1).builders
		grammar.builder_map[builder.id].should equal(builder)
	end
end
