require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "building" do
	before(:each) do
		@builder = SentenceBuilder::Builder.new
	end



	it "doesn't require an id" do
		@builder.id.should be_nil

		@builder = SentenceBuilder::Builder.new :id
		@builder.id.should equal(:id)
	end

	it "transfers a phrase into a Sequence" do
		@builder.should have(0).phrases
		@builder.phrase.should be_nil

		phrase = @builder.then
		phrase.should_not be_nil
		phrase.id.should be_nil

		@builder.should have(1).phrases
		@builder.phrases.last.should equal(phrase)
		@builder.phrase.should equal(phrase)

		#	one more
		phrase = @builder.and_then

		@builder.should have(2).phrases
		@builder.phrases.last.should equal(phrase)
		@builder.phrase.should equal(phrase)

		#	one more, with an id
		phrase = @builder.also

		@builder.should have(3).phrases
		@builder.phrases.last.should equal(phrase)
		@builder.phrase.should equal(phrase)
	end

	it "has id support for all phrase construction methods" do
		[
			:it,
			:then, :and_then, :also,
			:first, :last, :lastly,
		].each do |method|
			#	the method takes just an id
			phrase = @builder.__send__ method, method
			phrase.id.should equal(method)
		end

		[
			:before, :after,
		].each do |method|
			#	the method takes a reference, then the id
			phrase = @builder.__send__ method, :ref, method
			phrase.id.should equal(method)
		end
	end

	it "it with no id returns the current phrase, like #phrase" do
		@builder.it.should equal(@builder.phrase)

		@builder.then
		@builder.should have(1).phrases
		@builder.it.should equal(@builder.phrase)
	end

	it "it with an id creates a new phrase, like #then" do
		@builder.should have(0).phrases

		phrase = @builder.phrase
		@builder.it(:new).should_not equal(phrase)
		@builder.should have(1).phrases

		phrase = @builder.phrase

		@builder.it(:another).should_not equal(phrase)
		@builder.should have(2).phrases
	end

	it "will not permit duplicate phrase ids" do
		#	this will apply to all id-capable methods
		@builder.it(:first)
		@builder.it(:second)
		lambda { @builder.it(:first) }.should raise_error(SentenceBuilder::Error)
		lambda { @builder.it(:second) }.should raise_error(SentenceBuilder::Error)
	end



	it "has a 'say' shortcut" do
		@builder.should have(0).phrases

		phrase = @builder.say('hello')
		phrase.should_not be_nil
		phrase.id.should be_nil

		@builder.should have(1).phrases
		@builder.phrases.last.should equal(phrase)

		#	builds a new phrase
		#	even with the same words, it's different
		phrase = @builder.say('hello')

		@builder.should have(2).phrases

		#	we do not try to pull an id out of the say
		#	use and_then, or a similar explicit phrasing method
		phrase = @builder.say(:it, 'goodbye')
		phrase.id.should be_nil

		@builder.should have(3).phrases
	end



	#	best to test this once we have 'say' in the mix
	#
	it "'extend' operates in the context of the builder" do
		words = %w{ hello goodbye }

		@builder.extend do
			say words.shift
			and_then.say words.shift
		end

		@builder.should have(2).phrases
	end

	it "automatic 'extend' during construction" do
		words = %w{ hello goodbye }

		@builder = SentenceBuilder::Builder.new do
			say 'hello'
			also.say 'goodbye'
		end

		@builder.should have(2).phrases

		#	with an id
		@builder = SentenceBuilder::Builder.new(:id) do
			say 'hello'
			#	just testing syntactic sugar
			an(:other).says 'goodbye'
		end

		@builder.id.should equal(:id)
		@builder.should have(2).phrases
	end



	it "has an 'or' shortcut" do
		@builder.say 'hello'
		@builder.should have(1).phrases

		@builder.or.say 'aloha'
		@builder.should have(1).phrases

		@builder.append do
			alternately.say 'konnichiwa'
		end
		@builder.should have(1).phrases
	end

	it "the 'or' shortcut requires a pre-existing phrase" do
		lambda { @builder.or }.should raise_error(SentenceBuilder::Error)
	end



	it "categorizes orderings" do
		@builder.say 'middle'
		phrase = @builder.first.say 'beginning'

		@builder.should have(2).phrases
		@builder.should have(1).orderings
		@builder.should have(0).dependencies

		model = @builder.orderings.last
		model.type.should equal(:first)
		model.phrase.should equal(phrase)

		phrase = @builder.last.say 'end'

		@builder.should have(3).phrases
		@builder.should have(2).orderings

		model = @builder.orderings.last
		model.type.should equal(:last)
		model.phrase.should equal(phrase)

		phrase = @builder.anytime.say 'illustration'

		@builder.should have(4).phrases
		@builder.should have(3).orderings

		model = @builder.orderings.last
		model.type.should equal(:anytime)
		model.phrase.should equal(phrase)

		phrase = @builder.anytime.say 'table'
		@builder.orderings.last.phrase.should equal(phrase)

		phrase = @builder.last.say 'appendix'
		@builder.orderings.last.phrase.should equal(phrase)

		phrase = @builder.first.say 'contents'
		@builder.orderings.last.phrase.should equal(phrase)
	end

	it "has dependencies which require reference ids" do
		lambda { @builder.before.say 'no id' }.should raise_error
		lambda { @builder.after.say 'no id' }.should raise_error
	end

	it "categorizes dependencies" do
		phrase = @builder.before(:use).say 'open'

		@builder.should have(1).phrases
		@builder.should have(0).orderings
		@builder.should have(1).dependencies

		dep = @builder.dependencies.last
		dep.ref.should equal(:use)
		dep.phrase.should equal(phrase)
		dep.type.should equal(:before)

		phrase = @builder.after(:use).say 'close'

		@builder.should have(2).phrases
		@builder.should have(2).dependencies

		dep = @builder.dependencies.last
		dep.ref.should equal(:use)
		dep.phrase.should equal(phrase)
		dep.type.should equal(:after)

		phrase = @builder.before(:use).say 'destroy'
		@builder.dependencies.last.phrase.should equal(phrase)

		phrase = @builder.before(:use).say 'init'
		@builder.dependencies.last.phrase.should equal(phrase)
	end
end
