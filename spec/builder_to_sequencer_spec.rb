require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Builder, "to Sequencer" do
	it "turns an empty builder into an empty sequencer" do
		sequencer = MadderLib::Builder.new.to_sequencer

		sequencer.should have(0).steps
		sequencer.should have(0).anytimes
		sequencer.should have(0).befores
		sequencer.should have(0).afters
	end

	it "handles a single phrase" do
		builder = MadderLib::Builder.new()
		phrase = builder.say('puh-TAY-to').or.say('puh-TAH-to')
		sequencer = builder.to_sequencer

		sequencer.should have(1).steps
		sequencer.should have(0).anytimes
		sequencer.should have(0).befores
		sequencer.should have(0).afters

		sequencer.steps.last.should equal(phrase)
	end

	it "requires valid ids for befores and afters" do
		builder = madderlib do
			before(:missing).say('uh')
		end
		lambda { builder.to_sequencer }.should raise_error(MadderLib::Error)

		builder = madderlib do
			after(:missing).say('whoa')
		end
		lambda { builder.to_sequencer }.should raise_error(MadderLib::Error)
	end

	it "reminder... Builder#say doesn't derive a Phrase id" do
		phrase = nil
		builder = madderlib do
			phrase = say(:it, 'words')
			before(:it).say('something')
		end

		phrase.id.should be_nil
		lambda { builder.to_sequencer }.should raise_error(MadderLib::Error)
	end



	it "properly sequences firsts" do
		builder = madderlib :sequence_befores do
			says('loud')
			first.say('too')
			first.say('yer')
		end

		sequencer = builder.to_sequencer
		sequencer.should have(3).steps

		ids = []
		sequencer.each_phrase do |phrase|
			phrase.should have(1).instructions
			words = phrase.instructions.last.words
			words.should have(1).items

			ids << words.last
		end
		ids.should eql(%w{ yer too loud })
	end

	it "properly sequences lasts" do
		builder = madderlib do
			last.say('too')
			lastly.say('big')
			say('feet')
		end

		sequencer = builder.to_sequencer
		sequencer.should have(3).steps

		ids = []
		sequencer.each_phrase do |phrase|
			phrase.should have(1).instructions
			words = phrase.instructions.last.words
			words.should have(1).items

			ids << words.last
		end
		ids.should eql(%w{ feet too big })
	end



	it "before and after require referenceable ids" do
		#	doesn't complain on build
		builder = madderlib do
			before(:say).say 'before'
			say 'saying'
		end
		#	but during validation, etc.
		lambda { builder.validate }.should raise_error MadderLib::Error

		builder = madderlib do
			after(:say).say 'after'
			say 'saying'
		end
		lambda { builder.validate }.should raise_error MadderLib::Error
	end

	it "moves befores and afters into their own little worlds" do
		builder = madderlib do
			after(:say, :after).say 'after'
			before(:say, :before).say 'before'
			a(:say).says 'says'
		end

		sequencer = builder.to_sequencer
		sequencer.should have(1).steps

		#	before
		sequencer.should have(1).befores
		dep = sequencer.befores[:say]
		dep.should have(1).items
		dep.last.instructions.last.words.last.should eql('before')

		#	after
		sequencer.should have(1).afters
		dep = sequencer.afters[:say]
		dep.should have(1).items
		dep.last.instructions.last.words.last.should eql('after')

		#	some more, to prove ordering
		builder.append do
			after(:say).say 'end'
			before(:say).say 'begin'
		end

		sequencer = builder.to_sequencer

		#	before
		words = []
		sequencer.befores[:say].each do |before|
			words << before.instructions.last.words.last
		end
		words.should eql(['begin', 'before'])

		#	after
		words = []
		sequencer.afters[:say].each do |after|
			words << after.instructions.last.words.last
		end
		words.should eql(['after', 'end'])
	end



	it "anytime requires referenceable ids" do
		#	doesn't complain on build
		builder = madderlib do
			anytime.say('dipsy').before(:say)
			say 'doodle'
		end
		#	but during validation, etc.
		lambda { builder.validate }.should raise_error MadderLib::Error

		builder = madderlib do
			anytime.say('doodle').after(:say)
			say 'dipsy'
		end
		lambda { builder.validate }.should raise_error MadderLib::Error

		builder = madderlib do
			anytime.say('zzz').between(:night, :day)
			say 'ni-night'
		end
		lambda { builder.validate }.should raise_error MadderLib::Error
	end

	it "anytimes go into their own little world" do
		builder = madderlib :sequence_befores do
			anytime(:b).before(:say).say('before')
			anytime(:a).after(:say).say('after')
			anytime(:ab).say('somewhere').after(:b).before(:a)
			anytime(:t).between(:b, :a).say('tween')
			a(:say).says 'hello'
		end

		sequencer = builder.to_sequencer
		sequencer.should have(1).steps

		sequencer.should have(4).anytimes

		ids = []
		sequencer.anytimes.each do |anytime|
			id = anytime.id
			ids << id
			anytime.before.should_not be_nil unless :a == id
			anytime.after.should_not be_nil unless :b == id
		end

		ids.should eql([:b, :a, :ab, :t])
	end



	it "blends everything together perfectly" do
		builder = madderlib :sequence_befores do
			last(:late).say('4')
			first(:early).say('2')
			last.say('5')
			first.say('1')

			before(:late).say('3.9')
			after(:early).say('2.1')
			before(:early).say('1.9')
			after(:late).say('4.1')

			anytime.between(:early, :late).say('imaginary')
			anytime.say('random')

			says('3')
		end

		sequencer = builder.to_sequencer
		sequencer.should have(5).steps

		marks = []
		sequencer.steps.each do |phrase|
			phrase.should have(1).instructions
			words = phrase.instructions.last.words
			words.should have(1).items

			marks << words.last
		end
		marks.should eql(%w{ 1 2 3 4 5 })

		sequencer.befores[:early].last.instructions.last.words.last.should eql('1.9')
		sequencer.afters[:early].last.instructions.last.words.last.should eql('2.1')
		sequencer.befores[:late].last.instructions.last.words.last.should eql('3.9')
		sequencer.afters[:late].last.instructions.last.words.last.should eql('4.1')

		marks = []
		sequencer.anytimes.each do |phrase|
			marks << phrase.instructions.last.words.last
		end
		marks.should eql(%w{ imaginary random })
	end

	it "can collect the executed context" do
		builder = madderlib :outer do
			say madderlib(:inner_1) { say 'inner' }
			say 'plain'
			#	tried a do .. end block here, wasn't seen
			#		using { .. } does work
			say madderlib(:inner_2) {
				say madderlib(:deep_1) { say 'deep' }
				say madderlib(:deep_2) { say 'deeper' }
			}
		end

		context = nil
		words = builder.words {|ctx| context = ctx }
		words.should eql(%w{ inner plain deep deeper })

		context.should_not be_nil
		context.spoken.should have(3).phrases
		context.silent.should have(0).phrases
		context.instructions.should have(3).instructions

		#	just the inner ones
		context.contexts.should have(2).contexts

		#	hierarchical traversal
		#		which provides a full tree, including he the outer builder
		ids = []
		traverse = lambda do |ctx|
			ids << ctx.builder.id
			ctx.contexts.each {|sub| traverse.call(sub) }
		end
		traverse.call(context)

		ids.should have(5).ids
		ids.should eql([:outer, :inner_1, :inner_2, :deep_1, :deep_2 ])
	end

end
