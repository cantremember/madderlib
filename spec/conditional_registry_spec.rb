require File.join(File.dirname(__FILE__), 'spec_helper')



module MadderLib
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



describe MadderLib::Conditional::Registry do
	it "accumulates phrase preprations" do
		hits = []

		#	how to prepare each instruction
		MadderLib::Spec::Instruction.add_prepare { hits << :instruction_bare }
		MadderLib::Spec::Instruction.add_prepare {|context| hits << :instruction_context }

		#	how to prepare the phrase
		MadderLib::Spec::Phrase.add_prepare { hits << :phrase_bare }
		MadderLib::Spec::Phrase.add_prepare {|context| hits << :phrase_context }

		#	just confirming ...
		MadderLib::Spec::Phrase.new.methods.include?('instructions').should be_true

		#	add 2 instructions
		instance = MadderLib::Spec::Phrase.new
		instance.instructions << MadderLib::Spec::Instruction.new
		instance.instructions << MadderLib::Spec::Instruction.new
		instance.instructions.should have(2).instructions

		instance.prepare(MadderLib::Context::EMPTY)

		hits.should eql([
			:phrase_bare, :phrase_context,
			:instruction_bare, :instruction_context,
			:instruction_bare, :instruction_context,
		])
	end

	it "accumulates test preprations" do
		context = MadderLib::Context::EMPTY
		hits = []
		barely, contextual = true, true

		#	how to test each instruction
		MadderLib::Spec::Instruction.add_test do |instance|
			hits << :instruction_bare
			barely
		end
		MadderLib::Spec::Instruction.add_test do |instance, context|
			hits << :instruction_context
			contextual
		end

		#	all clear
		hits.clear
		instance = MadderLib::Spec::Instruction.new
		instance.test(context).should be_true
		hits.should eql([:instruction_bare, :instruction_context])

		#	bare terminate
		hits.clear
		barely = false
		instance = MadderLib::Spec::Instruction.new
		instance.test(context).should be_false
		hits.should eql([:instruction_bare])

		#	contextual terminate
		hits.clear
		barely, contextual = true, false
		instance = MadderLib::Spec::Instruction.new
		instance.test(context).should be_false
		hits.should eql([:instruction_bare, :instruction_context])
	end
end
