require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::KernelMethods, "simple examples" do

	it "README.doc" do
		puts madderlib {
			say 'hello,'
			say('welcome to').or.say("you're viewing")
			say('the README.doc')
		}.sentence
	end



	it "Snake 'n' Bacon" do
		builder = madderlib do
			say "i'm"

			#	build method #1
			#		empty un-said phrase
			#		then batch inject all options
			#		includes 'nothing' -- nil or ''
			and_then
			['sometimes', 'always', nil].each {|word| alternately.say(word) }

			#	build method #2
			#		englicized
			#		alternates, some with weights, or nothing
			say('quite').or(2).say('rather').or(2).say('so').or.nothing

			#	build method #3
			#		single start, then batch complete
			#		say one thing, add likely / weight if needed
			#		alternates, with weights if needed
			say 'salty'
			['smoky', 'peppery'].each {|word| alternately(2).say(word) }
		end
		builder.validate

		5.times { puts builder.sentence }

		#	just to clarify what we've done
		builder.should have(4).phrases
		builder.phrases[1].should have(3).instructions
		builder.phrases[2].should have(4).instructions
		builder.phrases[3].should have(3).instructions

		nothing_time = 0
		nothing_degree = 0
		pound_on do
			words = builder.words

			#	guaranteed
			words.include?("i'm").should be_true

			match = words.find do |item|
				%{ sometimes always }.include? item
			end
			nothing_time += 1 unless match

			match = words.find do |item|
				%{ quite rather so }.include? item
			end
			nothing_degree += 1 unless match

			#	something or other
			match = words.find do |item|
				%{ salty smoky peppery }.include? item
			end
			match.should_not be_nil
		end

		nothing_time.should be_close(33, 20)
		nothing_degree.should be_close(25, 20)
	end



	it "The Conet Project" do
		builder = madderlib do
			meta[:audio] = [
				'http://www.archive.org/download/ird059/tcp_d1_06_the_lincolnshire_poacher_mi5_irdial.mp3',
				'http://www.archive.org/download/ird059/tcp_d3_02_iran_iraq_jamming_efficacy_testting_irdial.mp3',
			]

			digits = lambda do |len|
				s = rand(10 ** len).to_s
				s = ('0' * (len - s.size)) + s
				s
			end

			say 'Lincolnshire Poacher'
			say { digits.call(5) }.repeat(10)

			say('~').repeat(6)

			200.times do
				say { s = digits.call(5); [s, s] }
			end

			say('~').repeat(6)

			say 'Lincolnshire Poacher'
		end
		builder.validate

		5.times { puts builder.sentence }
	end



	it "time-based user greeting" do
		user = Struct.new(:name)

		builder = madderlib do
			setup {|context| context[:hour] ||= Time.new.hour }
			a(:morning).says('top of the morning,').if {|c| Range.new(8, 12).include?(c[:hour]) }
			say('good afternoon,').if {|c| Range.new(12, 17).include?(c[:hour]) }
			say("g'night").if {|c| Range.new(19, 24).include?(c[:hour]) }
			say {|c| c[:user].name + '.' }
		end
		builder.validate

		puts builder.sentence {|c| c[:user] = user.new('joe')}

		puts builder.sentence {|c|
			c[:user] = user.new('fred')
			c[:hour] = 13
		}

		extended = builder.clone.extend { say('have a nice day!').if(:morning) }
		puts extended.sentence {|c|
			c[:user] = user.new('charlie')
			c[:hour] = 8
		}
	end



	it "combinatorial ranges" do
		#	useless, but at leasts tests composite operations
		builder = madderlib do
			say 'hello', 'and'
			say('never').if { false }.or.say('likely').likely(2).or.say('repeat').repeat(3).or(99).nothing
		end
		builder.validate
	end

end
