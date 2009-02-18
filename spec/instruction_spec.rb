require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Instruction do

	it "'say' ignores nils" do
		phrase = nil
		instruction = MadderLib::Instruction.new(phrase, nil)
		instruction.words.should have(0).words		instruction = MadderLib::Instruction.new(phrase, nil, :ok)
		instruction.words.should eql([:ok])
	end

	it "'say' ignores blanks" do
		phrase = nil
		instruction = MadderLib::Instruction.new(phrase, "")
		instruction.words.should have(0).words
		instruction = MadderLib::Instruction.new(phrase, :ok, '')
		instruction.words.should eql([:ok])
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
		#	simple values, and a Proc
		words = ['one', :two, lambda { 3 }].collect do |value|
			MadderLib::Instruction.wordify(value, MadderLib::Context::EMPTY)
		end

		words.should eql(%w{ one two 3 })

		#	arrays are stringified but retained
		words = [:a, [:b, :c], lambda { [:d, :e] }].collect do |value|
			MadderLib::Instruction.wordify(value, MadderLib::Context::EMPTY)
		end

		words.should eql(['a', ['b', 'c'], ['d', 'e']])

		builder = madderlib do
			say 'one'
			say :two
			say { 3 }
			say 'd', :e
			say { ['f', :g] }
		end
		builder.words.should eql(%w{ one two 3 d e f g })

		words = MadderLib::Instruction.wordify(builder, MadderLib::Context::EMPTY)
		words.should have(7).words
		words.should eql(%w{ one two 3 d e f g })
	end

end
