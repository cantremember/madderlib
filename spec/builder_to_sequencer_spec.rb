require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "to Sequencer" do
	it "turns an empty builder into an empty sequencer" do
		sequencer = SentenceBuilder::Builder.new.to_sequencer

		sequencer.should have(0).steps
		sequencer.should have(0).anytimes
		sequencer.should have(0).befores
		sequencer.should have(0).afters
	end

	it "handles a single phrase" do
		builder = SentenceBuilder::Builder.new()
		phrase = builder.say('puh-TAY-to').or.say('puh-TAH-to')
		sequencer = builder.to_sequencer

		sequencer.should have(1).steps
		sequencer.should have(0).anytimes
		sequencer.should have(0).befores
		sequencer.should have(0).afters

		sequencer.steps.last.should equal(phrase)
	end

	it "requires valid ids for befores and afters" do
		builder = sentence_builder do
			before(:missing).say('uh')
		end
		lambda { builder.to_sequencer }.should raise_error(SentenceBuilder::Error)

		builder = sentence_builder do
			after(:missing).say('whoa')
		end
		lambda { builder.to_sequencer }.should raise_error(SentenceBuilder::Error)
	end

	it "reminder... Builder#say doesn't derive a Phrase id" do
		phrase = nil
		builder = sentence_builder do
			phrase = say(:it, 'words')
			before(:it).say('something')
		end

		phrase.id.should be_nil
		lambda { builder.to_sequencer }.should raise_error(SentenceBuilder::Error)
	end



	it "properly sequences firsts" do
		builder = sentence_builder :sequence_befores do
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
		builder = sentence_builder do
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
		builder = sentence_builder do
			before(:say).say 'before'
			say 'saying'
		end
		#	but during validation, etc.
		lambda { builder.validate }.should raise_error SentenceBuilder::Error

		builder = sentence_builder do
			after(:say).say 'after'
			say 'saying'
		end
		lambda { builder.validate }.should raise_error SentenceBuilder::Error
	end

	it "moves befores and afters into their own little worlds" do
		builder = sentence_builder do
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
		builder = sentence_builder do
			anytime.say('dipsy').before(:say)
			say 'doodle'
		end
		#	but during validation, etc.
		lambda { builder.validate }.should raise_error SentenceBuilder::Error

		builder = sentence_builder do
			anytime.say('doodle').after(:say)
			say 'dipsy'
		end
		lambda { builder.validate }.should raise_error SentenceBuilder::Error

		builder = sentence_builder do
			anytime.say('zzz').between(:night, :day)
			say 'ni-night'
		end
		lambda { builder.validate }.should raise_error SentenceBuilder::Error
	end

	it "anytimes go into their own little world" do
		builder = sentence_builder :sequence_befores do
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
		builder = sentence_builder :sequence_befores do
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
end
