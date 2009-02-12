require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Closure do

	it "flat assuming" do
		one, two = nil, nil

		builder = sentence_builder do
			say(:one).assuming {|test| one }
			say(:two).presuming {|test| two }
		end

		[nil, true].each do |t|
			two = t
			[false, true].each do |o|
				one = o

				words = []
				words << 'one' if one
				words << 'two' if two

				builder.to_words.should eql(words)
			end
		end
	end

	it "flat forbidding" do
		one, two = nil, nil

		builder = sentence_builder do
			say(:one).forbidding {|test| one }
			say(:two).forbidding {|test| two }
		end

		[nil, true].each do |t|
			two = t
			[false, true].each do |o|
				one = o

				words = []
				words << 'one' unless one
				words << 'two' unless two

				builder.to_words.should eql(words)
			end
		end
	end

end
