require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Allowed do

	it "supports single assumption" do
		one, two = nil, nil

		builder = sentence_builder do
			say(:one).assuming {|test| one }
			say(:two).presuming {|test| two }
			say(:three).if { false }
		end

		[nil, true].each do |t|
			two = t
			[false, true].each do |o|
				one = o

				words = []
				words << 'one' if one
				words << 'two' if two

				builder.words.should eql(words)
			end
		end
	end

	it "supports multiple assumptions" do
		one, two = nil, nil

		builder = sentence_builder do
			say(:something).if {|test| one }.assuming {|test| two }
		end

		[nil, true].each do |t|
			two = t
			[false, true].each do |o|
				one = o

				words = []
				words << 'something' if one && two

				builder.words.should eql(words)
			end
		end
	end

	it "supports id-based assumption" do
		#	will say first = yes
		builder = sentence_builder do
			say(:yes).assuming(:spoken)
			first(:spoken).say(:said)
		end

		builder.words.should eql(%w{ said yes })

		#	will say last = no
		builder = sentence_builder do
			say(:yes).if(:spoken)
			last(:spoken).say(:said)
		end

		builder.words.should eql(%w{ said })
	end



	it "supports single forbiddance" do
		one, two = nil, nil

		builder = sentence_builder do
			say(:one).forbidding {|test| one }
			say(:two).forbidding {|test| two }
			say(:three).unless { true }
		end

		[nil, true].each do |t|
			two = t
			[false, true].each do |o|
				one = o

				words = []
				words << 'one' unless one
				words << 'two' unless two

				builder.words.should eql(words)
			end
		end
	end

	it "supports multiple forbiddance" do
		one, two = nil, nil

		builder = sentence_builder do
			say(:something).unless {|test| one }.forbidding {|test| two }
		end

		[nil, true].each do |t|
			two = t
			[false, true].each do |o|
				one = o

				words = []
				words << 'something' unless one || two

				builder.words.should eql(words)
			end
		end
	end

	it "supports id-based forbiddance" do
		#	will say first = no
		builder = sentence_builder do
			say(:yes).forbidding(:spoken)
			first(:spoken).say(:said)
		end

		builder.words.should eql(%w{ said })

		#	will say last = yes
		builder = sentence_builder do
			say(:yes).unless(:spoken)
			last(:spoken).say(:said)
		end

		builder.words.should eql(%w{ yes said })
	end
end
