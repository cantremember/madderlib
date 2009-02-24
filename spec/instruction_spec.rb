require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Instruction do

	it "'say' ignores nils" do
		phrase = nil
		context = MadderLib::Context.new

		#	nil, nothing else
		instruction = MadderLib::Instruction.new(phrase, nil)
		instruction.speak(context).should eql([])

		#	some counter-balancing value
		instruction = MadderLib::Instruction.new(phrase, nil, :value)
		instruction.speak(context).should eql(%w{ value })

		#	late-evaluated nil, array test as well
		instruction = MadderLib::Instruction.new(phrase, lambda { nil }, :proc)
		instruction.speak(context).should eql(%w{ proc })
	end

	it "'say' ignores blanks" do
		phrase = nil
		context = MadderLib::Context.new

		#	blank, nothing else
		instruction = MadderLib::Instruction.new(phrase, "")
		instruction.speak(context).should eql([])

		#	some counter-balancing value
		instruction = MadderLib::Instruction.new(phrase, :value, '')
		instruction.speak(context).should eql(%w{ value })

		#	late-evaluated blank
		instruction = MadderLib::Instruction.new(phrase, :proc, lambda { '' })
		instruction.speak(context).should eql(%w{ proc })
	end

	it "flattens Arrays" do
		phrase = nil
		context = MadderLib::Context.new

		instruction = MadderLib::Instruction.new(phrase, :a, [:b, :c])
		instruction.speak(context).should eql(%w{ a b c })

		instruction = MadderLib::Instruction.new(phrase, [:a, :b, :c])
		instruction.speak(context).should eql(%w{ a b c })

		instruction = MadderLib::Instruction.new(phrase, :a, [:b, '', [:c, nil, :d]])
		instruction.speak(context).should eql(%w{ a b c d })

		instruction = MadderLib::Instruction.new(phrase, :a, [1, nil, [lambda { :proc }, lambda { ''}, :d]])
		instruction.speak(context).should eql(%w{ a 1 proc d })
	end

	it "handles sub-Builders" do
		phrase = nil
		context = MadderLib::Context.new

		#	a nice variety of challenges
		string = madderlib { say 'string' }
		one = madderlib { say 1 }
		array = madderlib { say [:a, :b] }
		symbol = madderlib { say :symbol }
		proc = madderlib { say { :proc } }

		#	simple
		instruction = MadderLib::Instruction.new(phrase, string, one, array, symbol, proc)
		instruction.speak(context).should eql(%w{ string 1 a b symbol proc })

		#	crazy
		#		procs returning Builders, arrays of Builders, etc
		instruction = MadderLib::Instruction.new(phrase, [ string, [ one , lambda { [ array, symbol, proc ] } ]])
		instruction.speak(context).should eql(%w{ string 1 a b symbol proc })
	end

	it "handles Procs" do
		#	this is a pretty serious coverage case
		#		includes Proc-of-a-Proc, etc
		words = [ 'one', :two, 3, lambda { :four }, madderlib { say 5 }, [ :six, lambda { 7 } ] ]
		builder = madderlib do
			say { words.shift }.repeat { ! words.empty? }
		end
		builder.words.should eql(%w{ one two 3 four 5 six 7 })
	end



	it "can convert Phrase results into words" do
		#
		#	this test may be redundant to the above
		#	but it's not as thorough
		#

		context = MadderLib::Context.new

		#	simple values, and a Proc
		words = ['one', :two, nil, lambda { 3 }].collect do |value|
			MadderLib::Instruction.wordify(value, context)
		end

		words.should eql(['one', 'two', nil, '3'])

		#	arrays are stringified but retained
		#		flattening within array
		#		nil considerations are retained
		words = [:a, [:b, [:c, nil]], lambda { [:d, :e] }].collect do |value|
			MadderLib::Instruction.wordify(value, context)
		end

		words.should eql(['a', ['b', 'c', nil], ['d', 'e']])

		builder = madderlib do
			say 'one'
			say :two
			say { 3 }
			#	both ignored
			say nil
			say { nil }
			#	back to real data
			say 'd', :e
			say { ['f', :g] }
		end
		builder.words.should eql(%w{ one two 3 d e f g })

		words = MadderLib::Instruction.wordify(builder, context)
		words.should have(7).words
		words.should eql(%w{ one two 3 d e f g })
	end

end
