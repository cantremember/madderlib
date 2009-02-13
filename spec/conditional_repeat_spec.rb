require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Repeat do

	it "no repeat = once" do
		builder = sentence_builder do
			say(:one)
			say(:two)
		end

		builder.to_words.should eql(%w{ one two })
	end

	it "supports simple repeating" do
		builder = sentence_builder do
			say(:once)
			say(:twice).repeat(2)
			say(:thrice).times(3)
		end

		builder.to_words.should eql(%w{ once twice twice thrice thrice thrice })
	end

	it "supports a 0-repeat, which blocks the instruction" do
		builder = sentence_builder do
			say(:one)
			say(:two).times(0)
		end

		builder.to_words.should eql(%w{ one })
	end

	it "supports Ranged repeating" do
		builder = sentence_builder do
			say(:once)
			say(:few).repeat(Range.new(3, 5))
			say(:couple).times(3, 5)
		end

		pound_on do
			words = builder.to_words
			words.shift.should eql('once')

			repeat = []
			repeat << words.shift while words.first == 'few'
			repeat.size.should be_close(4, 1.1)

			repeat = []
			repeat << words.shift while words.first == 'couple'
			repeat.size.should be_close(4, 1.1)
		end
	end

	it "supports arbitrary repeating" do
		men = [:fred, :barney]
		women = [:wilma, :betty]

		builder = sentence_builder :repeat_exhausting do
			say(:intro)
			a(:man).says { men.shift }.repeat { ! men.empty?}
			a(:woman).says { women.shift }.while { ! women.empty?}
		end

		builder.to_words.should eql(%w{ intro fred barney wilma betty })

		#	the next pass should be exhausted
		builder.to_words.should eql(%w{ intro })
	end

end
