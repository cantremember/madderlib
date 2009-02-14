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
			say 'quite'
			['rather', 'so'].each {|word| alternately.say(word) }
			alternately.nothing
			say('salty')
			['smoky', 'peppery'].each {|word| alternately.say(word) }
		end

		nothings = 0
		pound_on do
			words = builder.words

			#	guaranteed
			words.include?("i'm").should be_true

			match = words.find do |item|
				%{ quite rather so }.include? item
			end
			nothings += 1 unless match

			#	something or other
			match = words.find do |item|
				%{ salty smoky peppery }.include? item
			end
			match.should_not be_nil
		end

		nothings.should be_close(25, 20)
	end

end
