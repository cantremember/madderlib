require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib, "tests from the documentation" do

	it "Builder.initialize" do
		builder = MadderLib::Builder.new
		builder.id.should be_nil
		builder.should have(0).phrases
		#
		builder = MadderLib::Builder.new :id
		builder.id.should equal(:id)
		builder.should have(0).phrases
		#
		builder = MadderLib::Builder.new do
			say 'no id'
		end
		builder.id.should be_nil
		builder.sentence.should eql('no id')
		#
		builder = MadderLib::Builder.new :id do
			say {|context| context.builder.id }
		end
		builder.sentence.should eql('id')
	end

	it "Builder.append" do
		builder = MadderLib::Builder.new { say 'construct' }
		builder.append { say 'extended' }
		builder.extend { say 'appending' }
		builder.words.should eql(%w{ construct extended appending })
	end

	it "Builder.clone" do
		original = MadderLib::Builder.new do
			meta[:meta] = :original
			say 'original'
			and_then(:shared).say('initial').likely(1)
		end
		#
		cloned = original.clone
		cloned[:meta] = :cloned
		cloned.extend { say 'cloned' }
		#
		done = :original
		cloned.setup { done = :cloned }
		#
		shared = original.phrases.find {|phrase| phrase.id == :shared }
		shared.instructions.first.words << 'added'
		#
		original[:meta].should equal(:original)
		original.sentence.should eql('original initial added')
		done.should equal(:original)
		#
		cloned[:meta].should equal(:cloned)
		cloned.sentence.should eql('original initial added cloned')
		done.should equal(:cloned)
	end

	it "Builder.setup" do
		builder = MadderLib::Builder.new do
			say {|context| context[:setup] }
		end
		builder.setup {|context| context[:setup] << 2 }
		builder.setup {|context| context[:setup] << 3 }
		builder.setup(:first) {|context| context[:setup] = [1] }
		#
		builder.sentence.should eql('1 2 3')
	end

	it "Builder.teardown" do
		builder = MadderLib::Builder.new do
			say 'teardown'
		end
		markers = []
		builder.teardown {|context| markers << 2 }
		builder.teardown {|context| markers << 3 }
		builder.teardown(:first) {|context| markers = [1] }
		#
		builder.sentence.should eql('teardown')
		markers.should eql([1, 2, 3])
	end

	it "Builder.meta accessors" do
		builder = MadderLib::Builder.new do
			meta[:key] = :value
		end
		builder[:key].should equal(:value)
	end

	it "Builder.phrase" do
		builder = MadderLib::Builder.new do
			say 'yes'
			phrase.if {|context| context.builder[:activated] == true }
			it.repeat(3)
		end
		#
		builder.should have(1).phrases
		builder.phrase.should have(1).instructions
		#
		builder.should have(0).words
		#
		builder[:activated] = true
		builder.sentence.should eql('yes yes yes')
	end

	it "Builder.and_then" do
		builder = MadderLib::Builder.new do
			say 'first'
			and_then.say 'and_then'
			also.say 'also'
		end
		builder.and.say 'and'
		builder.then.say 'then'

		builder.sentence.should eql('first and_then also and then')
	end

	it "Builder.an" do
		builder = MadderLib::Builder.new do
			say 'first'
			a(:second).says 'second'
			an(:other).says 'other'
		end

		builder.sentence.should eql('first second other')
	end

	it "Builder.first" do
		builder = MadderLib::Builder.new do
			say 'something'
			first.say 'say'
		end
		builder.sentence.should eql('say something')

		builder.first.say 'first'
		builder.sentence.should eql('first say something')
	end

	it "Builder.last" do
		builder = MadderLib::Builder.new do
			last.say 'said'
			say 'something'
		end
		builder.sentence.should eql('something said')

		builder.last.say 'last'
		builder.sentence.should eql('something said last')
	end

	it "Builder.anywhere" do
		builder = MadderLib::Builder.new do
			say 'top'
			say 'here'
			say 'there'
			say 'bottom'
		end
		builder.anywhere.say 'anywhere'

		words = builder.words
		words.should have(5).words
		words.find_all {|word| word == 'anywhere'}.should have(1).word

		builder.it.recurs(2)

		words = builder.words
		words.should have(6).words
		words.find_all {|word| word == 'anywhere'}.should have(2).word
	end

	it "Builder.before" do
		builder = MadderLib::Builder.new do
			an(:always).says 'always'
			a(:sometimes).says('sometimes').if {|context| context.builder[:sometimes] == true }
			before(:always).say 'before-always'
			before(:sometimes, :depends).say 'before-sometimes'
			before(:depends).say 'depends'
		end

		builder.sentence.should eql('before-always always')

		builder[:sometimes] = true

		builder.sentence.should eql('before-always always depends before-sometimes sometimes')
	end

	it "Builder.after" do
		builder = MadderLib::Builder.new do
			an(:always).says 'always'
			a(:sometimes).says('sometimes').if {|context| context.builder[:sometimes] == true }
			after(:always).say 'after-always'
			after(:sometimes, :depends).say 'after-sometimes'
			after(:depends).say 'depends'
		end

		builder.sentence.should eql('always after-always')

		builder[:sometimes] = true

		builder.sentence.should eql('always after-always sometimes after-sometimes depends')
	end

	it "Builder.say" do
		builder = MadderLib::Builder.new do
			says 'word'
			say :symbol
			say { 'lambda' }
		end
		builder.should have(3).phrases
		builder.sentence.should eql('word symbol lambda')
	end

	it "Builder.alternately" do
		builder = MadderLib::Builder.new do
			says 'word'
			alternately.says :symbol
		end
		builder.or.say { 'lambda' }

		builder.should have(1).phrases
		builder.phrase.should have(3).instructions
		%w{ word symbol lambda}.include?(builder.sentence).should be_true
	end

	it "Build.words" do
		builder = MadderLib::Builder.new do
			says 'word'
			say :symbol, [:with, :hierarchy]
			say { 'lambda' }
		end
		builder.words.should eql(%w{ word symbol with hierarchy lambda })
	end

	it "Build.sentence" do
		builder = MadderLib::Builder.new do
			says 'word'
			say :symbol, [:with, :hierarchy]
			say { 'lambda' }
		end
		builder.sentence.should eql('word symbol with hierarchy lambda')
	end



	it "Context.state" do
		context = MadderLib::Context.new
		state = context.state(:state)
		state.should_not be_nil

		state[:key] = :value
		context.state(:state)[:key].should equal(:value)
	end

	it "Context.data accessors" do
		context = MadderLib::Context.new
		context.data[:key] = :value

		context[:key].should equal(:value)
	end

	it "Context::EMPTY" do
		MadderLib::Context::EMPTY.frozen?.should be_true

		lambda { MadderLib::Context::EMPTY.state(:immutable) }.should raise_error TypeError
		lambda { MadderLib::Context::EMPTY[:immutable] = true }.should raise_error TypeError
	end



	it "KernelMethods.madderlib" do
		builder = madderlib do
			say 'no id'		end
		madderlib_grammar.builders.include?(builder).should be_true
		madderlib_grammar.builder_map.values.include?(builder).should_not be_true

		builder = madderlib :id do
			say 'has id'
		end
		madderlib_grammar.builders.include?(builder).should be_true
		madderlib_grammar.builder_map.values.include?(builder).should be_true
	end

	it "KernelMethods.madderlib" do
		builder = madderlib do
			say 'no id'
		end
		madderlib_grammar.builders.include?(builder).should be_true
		madderlib_grammar.builder_map.values.include?(builder).should_not be_true

		builder = madderlib :id do
			say 'has id'
		end
		madderlib_grammar.builders.include?(builder).should be_true
		madderlib_grammar.builder_map.values.include?(builder).should be_true
	end



	it "Grammar.new_instance" do
		current = MadderLib::Grammar.new_instance
		current.should have(0).builders
		current.should equal(MadderLib::Grammar.get_instance)

		one = madderlib { say 'one' }
		current.should have(1).builders
		current.builders.include?(one).should be_true

		fresh = MadderLib::Grammar.new_instance
		fresh.should equal(MadderLib::Grammar.get_instance)

		two = madderlib { say 'two' }
		fresh.should have(1).builders
		fresh.builders.include?(two).should be_true

		current.should_not equal(MadderLib::Grammar.get_instance)
		current.builders.include?(two).should_not be_true
	end

	it "Grammar.add" do
		grammar = MadderLib::Grammar.new_instance

		builder = madderlib { say 'exists' }
		x = grammar.add(builder)
		x.should equal(builder)
		grammar.should have(1).builders
		grammar.builder_map.should have(0).keys

		builder = grammar.add { say 'no id' }
		grammar.should have(2).builders
		grammar.builder_map.should have(0).keys
		builder.sentence.should eql('no id')

		builder = grammar << :id
		grammar.should have(3).builders
		grammar.builder_map.values.include?(builder).should be_true
		builder.sentence.should eql('')
	end

	it "Grammar.builder_map accessors" do
		grammar = MadderLib::Grammar.new_instance

		builder = grammar.add(:id) { say 'has id' }
		grammar[:id].should equal(builder)
	end

end
