require File.join(File.dirname(__FILE__), 'spec_helper')



module SentenceBuilder
	module Spec
		class Phrase
			class << self
				include Conditional::Registry::Static
			end
			include Conditional::Registry::Instance

			def instructions
				@instructions ||= []
			end
		end

		class Instruction
			class << self
				include Conditional::Registry::Static
			end
			include Conditional::Registry::Instance
		end
	end
end



describe SentenceBuilder::Conditional::Registry do
	it "accumulates phrase preprations" do
		hits = []

		#	how to prepare each instruction
		SentenceBuilder::Spec::Instruction.add_prepare { hits << :instruction_bare }
		SentenceBuilder::Spec::Instruction.add_prepare {|context| hits << :instruction_context }

		#	how to prepare the phrase
		SentenceBuilder::Spec::Phrase.add_prepare { hits << :phrase_bare }
		SentenceBuilder::Spec::Phrase.add_prepare {|context| hits << :phrase_context }

		#	just confirming ...
		SentenceBuilder::Spec::Phrase.new.methods.include?('instructions').should be_true

		#	add 2 instructions
		instance = SentenceBuilder::Spec::Phrase.new
		instance.instructions << SentenceBuilder::Spec::Instruction.new
		instance.instructions << SentenceBuilder::Spec::Instruction.new
		instance.instructions.should have(2).instructions

		instance.prepare(SentenceBuilder::Context::EMPTY)

		hits.should eql([
			:phrase_bare, :phrase_context,
			:instruction_bare, :instruction_context,
			:instruction_bare, :instruction_context,
		])
	end

	it "accumulates test preprations" do
		context = SentenceBuilder::Context::EMPTY
		hits = []
		barely, contextual = true, true

		#	how to test each instruction
		SentenceBuilder::Spec::Instruction.add_test do |instance|
			hits << :instruction_bare
			barely
		end
		SentenceBuilder::Spec::Instruction.add_test do |instance, context|
			hits << :instruction_context
			contextual
		end

		#	all clear
		hits.clear
		instance = SentenceBuilder::Spec::Instruction.new
		instance.test(context).should be_true
		hits.should eql([:instruction_bare, :instruction_context])

		#	bare terminate
		hits.clear
		barely = false
		instance = SentenceBuilder::Spec::Instruction.new
		instance.test(context).should be_false
		hits.should eql([:instruction_bare])

		#	contextual terminate
		hits.clear
		barely, contextual = true, false
		instance = SentenceBuilder::Spec::Instruction.new
		instance.test(context).should be_false
		hits.should eql([:instruction_bare, :instruction_context])
	end
end
