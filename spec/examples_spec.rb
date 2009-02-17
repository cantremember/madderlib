require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::KernelMethods, "simple examples" do

	it "combinatorial ranges" do
		#	useless, but at leasts tests composite operations
		builder = madderlib do
			say 'hello', 'and'
			say('never').if { false }.or.say('likely').likely(2).or.say('repeat').repeat(3).or(99).nothing
		end
		builder.validate	end

	it "bacon says" do
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

end
