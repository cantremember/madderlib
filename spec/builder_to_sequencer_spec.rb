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
			before(:missing).say('uh')		end
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
		sequencer.each do |phrase|
			phrase.should have(1).instructions
			words = phrase.instructions.last.words
			words.should have(1).items

			ids << words.last
		end
		ids.should eql(%w{ yer too loud })
	end

	it "properly sequences lasts" do
		builder = sentence_builder :sequence_befores do
			last.say('too')
			lastly.say('big')
			says('feet')
		end

		sequencer = builder.to_sequencer
		sequencer.should have(3).steps

		ids = []
		sequencer.each do |phrase|
			phrase.should have(1).instructions
			words = phrase.instructions.last.words
			words.should have(1).items

			ids << words.last
		end
		ids.should eql(%w{ feet too big })
	end

	it "firsts and lasts" do
		builder = sentence_builder :sequence_befores do
			last.say('4')
			first.say('2')
			says('3')
			last.say('5')
			first.say('1')
		end

		sequencer = builder.to_sequencer
		sequencer.should have(5).steps

		ids = []
		sequencer.each do |phrase|
			phrase.should have(1).instructions
			words = phrase.instructions.last.words
			words.should have(1).items

			ids << words.last
		end
		ids.should eql(%w{ 1 2 3 4 5 })
	end

end
