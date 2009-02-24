require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Instruction do

	it "'say' ignores nils" do
		phrase = nil
		#	no sequencer
		context = MadderLib::Context.new

		#	nil, nothing else
		instruction = MadderLib::Instruction.new(phrase, nil)
		instruction.words.should have(0).words		instruction.speak(context).should eql([])

		#	some counter-balancing value
		instruction = MadderLib::Instruction.new(phrase, nil, :value)
		instruction.words.should eql([:value])
		instruction.speak(context).should eql(%w{ value })

		#	late-evaluated nil, array test as well
		instruction = MadderLib::Instruction.new(phrase, lambda { nil }, :proc)
		instruction.words.should have(2).words
		instruction.speak(context).should eql(%w{ proc })
	end

	it "'say' ignores blanks" do
		phrase = nil
		#	no sequencer
		context = MadderLib::Context.new

		#	blank, nothing else
		instruction = MadderLib::Instruction.new(phrase, "")
		instruction.words.should have(0).words
		instruction.speak(context).should eql([])

		#	some counter-balancing value
		instruction = MadderLib::Instruction.new(phrase, :value, '')
		instruction.words.should eql([:value])
		instruction.speak(context).should eql(%w{ value })

		#	late-evaluated blank
		#		is actually kept!  it's not known to be blank until evaluation
		#		if the evaluation wants a blank, let it have one
		#		if not, then it should return nil
		instruction = MadderLib::Instruction.new(phrase, :proc, lambda { '' })
		instruction.words.should have(2).words
		instruction.speak(context).should eql(['proc', ''])
	end

	it "flattens Arrays" do
		phrase = nil
		instruction = MadderLib::Instruction.new(phrase, :a, [:b, :c])
		instruction.words.should eql([:a, :b, :c])

		#	but not Hashes
		instruction = MadderLib::Instruction.new(phrase, :a, { :b => :c })
		instruction.words.should have(2).words
		instruction.words.first.should equal(:a)
		instruction.words.last.should be_a(Hash)
	end



	it "can convert phrase results into words" do
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
