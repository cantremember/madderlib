require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Grammar do
	before(:each) do
		@class = MadderLib::Grammar

		#	close any pre-existing grammar
		madderlib_grammar.close
	end



	it "get_instance returns a singleton" do
		@class.get_instance.should equal(@class.get_instance)
	end

	it "retains a list of unique Builders, and a map of id'd Builders" do
		grammar = @class.get_instance

		grammar.should have(0).builders
		grammar.builder_map.should have(0).builders

		#	un-id'd
		builder = MadderLib::Builder.new
		grammar << builder

		grammar.should have(1).builders
		grammar.builders.last.should equal(builder)
		grammar.builder_map.should have(0).builders

		#	duplicate
		grammar << builder

		grammar.should have(1).builders
		grammar.builder_map.should have(0).builders

		#	id'd
		builder = MadderLib::Builder.new(:named)
		grammar << builder

		grammar.should have(2).builders
		grammar.builders.last.should equal(builder)
		grammar.builder_map.should have(1).builders
		grammar.builder_map[builder.id].should equal(builder)
	end



	it "can be closed, even using the Kernel context" do
		madderlib :one do
			say :one
		end
		madderlib :two do
			say :two
		end

		held = madderlib_grammar
		held.close

		held.builders.should have(2).builders
		[:one, :two].each {|key| held.builder_map[key].should_not be_nil }

		#	more builders
		madderlib :three do
			say :three
		end

		open = madderlib_grammar
		open.builders.should have(1).builder
		[:three].each {|key| open.builder_map[key].should_not be_nil }

		#	does not impact the one we locked down
		held.builders.should have(2).builders
		[:one, :two].each {|key| held.builder_map[key].should_not be_nil }

		#	sorry, you're frozen
		lambda { held.add :anything }.should raise_error TypeError
	end

	it "has many ways to add a Builder" do
		grammar = @class.new

		builder = grammar.add MadderLib::Builder.new :explicit
		builder.should equal(grammar.builders.last)

		builder.id.should equal(:explicit)
		grammar.add(:implicit) { say('implicit') }
		builder = grammar.builders.last
		builder.id.should equal(:implicit)
		builder.to_s.should eql('implicit')

		builder = grammar.add { say('no-id') }
		builder.should equal(grammar.builders.last)

		builder.id.should be_nil
		builder.to_s.should eql('no-id')
	end

	it "supports map-like access for Builders" do
		grammar = MadderLib::Grammar.new

		grammar[:test].should be_nil

		grammar[:test] ||= madderlib { }
		grammar[:test].should_not be_nil
	end

end
