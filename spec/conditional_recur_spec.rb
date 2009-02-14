require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Recur do

	it "only occurs once if not told otherwise" do
		builder = sentence_builder do
			#	give it boundaries
			say(:start)
			anytime.say(:any)
			say(:end)
		end

		builder.phrases.each do |phrase|
			phrase.recurs?.should be_false if phrase.respond_to?(:recurs?)
		end

		builder.words.should eql(%w{ start any end })
	end

	it "supports simple recurrence" do
		builder = sentence_builder do
			#	give it boundaries
			say(:start)
			anytime.recurring(2).say(:any)
			say(:end)
		end

		builder.phrases.each do |phrase|
			phrase.recurs?.should be_true if phrase.respond_to?(:recurs?)
		end

		builder.words.should eql(%w{ start any any end })
	end

	it "supports a 0-recurrence, which blocks the phrase" do
		builder = sentence_builder do
			say(:start)
			anytime.recur(0).say(:never)
			say(:end)
		end

		builder.words.should eql(%w{ start end })
	end

	it "supports Ranged recurrence" do
		builder = sentence_builder do
			#	give it boundaries
			say(:start)
			anytime.recurring(Range.new(3, 5)).say(:few)
			anytime.recurring(3, 5).say(:couple)
			say(:end)
		end

		pound_on do
			words = builder.words

			words.shift.should eql('start')
			words.pop.should eql('end')

			count = 0
			words.each {|word| count += 1 if word == 'few' }
			count.should be_close(4, 1.1)

			count = 0
			words.each {|word| count += 1 if word == 'couple' }
			count.should be_close(4, 1.1)
		end
	end

	it "supports arbitrary recurrence" do
		spices = [:parsley, :sage, :rosemary, :thyme]
		shoulds = spices.clone

		builder = sentence_builder :repeat_exhausting do
			say(:start)
			#	if these don't exist, positioning isn't random
			#		it's just a visual confirmation from initial testing
			say(:salt)
			say(:pepper)
			say(:flour)
			say(:end)

			anytime.recur { ! spices.empty? }.say { spices.shift }
		end

		words = builder.words
		words.shift.should eql('start')
		words.pop.should eql('end')

		#	and all of the others should be present
		shoulds << :salt << :pepper << :flour
		shoulds.each do |spice|
			words.index(spice.to_s).should_not be_nil
		end

		#	the next pass should be exhausted
		builder.words.should eql(%w{ start salt pepper flour end })
	end

end
