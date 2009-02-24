%w{ generator }.each {|lib| require lib }



module MadderLib
	#= Builder
	#
	#A builder object for MadderLib sentences.
	#
	#The builder is constructed to include all of the Phrases (rules) for building a sentence.
	#
	#Traditionally this is done through KernelMethods shortcuts:
	#  builder = madderlib :id do
	#    say 'through Kernel'
	#    ...
	#  end
	#
	#This can also be done through standard construction
	#  builder = MadderLib::Builder.new(:id) do
	#    say('through construction')
	#    ...
	#  end
	#
	#Each time you invoke the builder using one of the following methods, its Phrases are executed from scratch using a new build context:
	#* sentence : returns the resulting words as a composite String
	#* words : returns a list of all the resulting words
	#* each_words : iterates through each of the resulting words
	#
	#You can clone an existing builder.  The resulting object is 'deeply' cloned.
	#
	#You can extend or append additional rules to an existing builder.
	#  builder.extend { say 'something more'; ... }
	#
	#You can add multiple setup and teardown blocks to the builder, which provide access to the active build context.
	#
	#All of the other features of the Builder involve management of and dispatching to the current Phrase.
	class Builder
		include Enumerable

		#The (optional) id of the Builder
		attr_reader :id
		#An Array of each Phrase (rule) within the Builder
		attr_reader :phrases
		#An Array containing the id from each Phrase which has one (they're optional)
		attr_reader :phrase_ids
		#A Hash of arbitrary meta-data for the Builder.
		#It is reserved for custom developer logic; the Builder doesn't consider its meta-data
		attr_reader :meta

		#Constructs a new Builder.
		#The id is optional.
		#When a block is provided, it is used to extend the new (empty) Builder
		#
		#Examples:
		#  builder = MadderLib::Builder.new
		#  builder.id.should be_nil
		#  builder.should have(0).phrases
		#
		#  builder = MadderLib::Builder.new :id
		#  builder.id.should equal(:id)
		#  builder.should have(0).phrases
		#
		#  builder = MadderLib::Builder.new do
		#    say 'no id'
		#  end
		#  builder.id.should be_nil
		#  builder.sentence.should eql('no id')
		#
		#  builder = MadderLib::Builder.new :id do
		#    say {|context| context.builder.id }
		#  end
		#  builder.sentence.should eql('id')
		def initialize(id=nil, &block)
			@id = id
			@phrases, @phrase_ids = [], []
			@ordered, @depends = [], []
			@setup, @teardown = [], []
			@meta = {}

			self.extend &block if block_given?
			self
		end

		#Executes the block provided within the context of the Builder instance.
		#This provides easy contextual access to say, or, first, anytime, and all other instance methods.
		#
		#Examples:
		#  builder = MadderLib::Builder.new { say 'construct' }
		#  builder.append { say 'extended' }
		#  builder.extend { say 'appending' }
		#  builder.words.should eql(%w{ construct extended appending })
		def append(&block)
			raise Error, 'extending block is required' unless block_given?

			#	evaluate in our context
			#	available in scope
			#		closure locals
			#		static methods, if you specify self.class
			#		instance variables and methods
			#	unavailable
			#		any methods in closure scope (sorry, Tennessee)
			self.instance_eval &block
			self
		end
		alias :extend :append

		#Creates a deep-clone of the builder.
		#You can extend the new builder's Phrases, or add new setup blocks, without impacting the original.
		#The clone is added to the active Grammar.
		#
		#Note that the two builders will share the same <i>original</i> Phrase list.
		#If you modify one of them behind-the-scenes, that change will be shared by <i>both</i> builders.
		#
		#Examples:
		#  original = MadderLib::Builder.new do
		#    meta[:meta] = :original
		#    say 'original'
		#    and_then(:shared).say('initial').likely(1)
		#  end
		#
		#  cloned = original.clone
		#  cloned[:meta] = :cloned
		#  cloned.extend { say 'cloned' }
		#
		#  done = :original
		#  cloned.setup { done = :cloned }
		#
		#  shared = original.phrases.find {|phrase| phrase.id == :shared }
		#  shared.instructions.first.words << 'added'
		#
		#  original[:meta].should equal(:original)
		#  original.sentence.should eql('original initial added')
		#  done.should equal(:original)
		#
		#  cloned[:meta].should equal(:cloned)
		#  cloned.sentence.should eql('original initial added cloned')
		#  done.should equal(:cloned)
		def clone(id=nil)
			o = super()

			#	deeper copy
			@phrases = @phrases.clone
			@phrase_ids = @phrase_ids.clone
			@ordered = @ordered.clone
			@depends = @depends.clone
			@setup = @setup.clone
			@teardown = @teardown.clone
			@meta = @meta.clone

			#	don't want two of them floating around with the same id
			o.instance_variable_set :@id, id

			#	put it into the grammar
			#		most importantly,
			Grammar.get_instance.add o
			o
		end



		#Adds a setup block to the builder.
		#
		#The block is executed before the builder invokes its Phrases (rules).
		#The block can either take no arguments, or a Context.
		#
		#Subsequent blocks are executed in the order provided.
		#If you provide <code>:first</code> as an argument, the block will occur prior to any existing blocks.
		#It would of course be preceded by any subsequent block which says that it is <code>:first</code>.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say {|context| context[:setup] }
		#  end
		#  builder.setup {|context| context[:setup] << 2 }
		#  builder.setup {|context| context[:setup] << 3 }
		#  builder.setup(:first) {|context| context[:setup] = [1] }
		#
		#  builder.sentence.should eql('1 2 3')
		def setup(*args, &block)
			Context.validate(block)

			#	ordering
			if args.include?(:first)
				@setup.unshift block
			else
				@setup.push block
			end

			self
		end

		#Adds a teardown block to the builder.
		#
		#The block is executed after the builder has invoked its Phrases (rules).
		#The block can either take no arguments, or a Context.
		#
		#Subsequent blocks are executed in the order provided.
		#If you provide <code>:first</code> as an argument, the block will occur prior to any existing blocks.
		#It would of course be preceded by any subsequent block which says that it is <code>:first</code>.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say 'teardown'
		#  end
		#  markers = []
		#  builder.teardown {|context| markers << 2 }
		#  builder.teardown {|context| markers << 3 }
		#  builder.teardown(:first) {|context| markers = [1] }
		#
		#  builder.sentence.should eql('teardown')
		#  markers.should eql([1, 2, 3])
		def teardown(*args, &block)
			Context.validate(block)

			#	ordering
			if args.include?(:first)
				@teardown.unshift block
			else
				@teardown.push block
			end

			self
		end



		#Provides convenient access to the meta Hash.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    meta[:key] = :value
		#  end
		#  builder[:key].should equal(:value)
		def [](k)
			@meta[k]
		end

		#Provides convenient access to the meta Hash.
		#
		#See:  []
		def []=(k, v)
			@meta[k] = v
		end



		#Returns the current Phrase.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say 'yes'
		#    phrase.if {|context| context.builder[:activated] == true }
		#    it.repeat(3)
		#  end
		#
		#  builder.should have(1).phrases
		#  builder.phrase.should have(1).instructions
		#
		#  builder.should have(0).words
		#
		#  builder[:activated] = true
		#  builder.sentence.should eql('yes yes yes')
		def phrase
			@phrases.last
		end
		alias :it :phrase

		#Allocates another Phrase.
		#An optional Phrase id can be provided.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say 'first'
		#    and_then.say 'and_then'
		#    also.say 'also'
		#  end
		#  builder.and.say 'and'
		#  builder.then.say 'then'
		def and_then(id=nil)
			add_id id
			@phrases << Phrase.new(self, id)
			@phrases.last
		end
		alias :also :and_then
		alias :and :and_then
		alias :then :and_then

		#Allocates another Phrase, where an id is required.
		#This is semantic sugar.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say 'first'
		#    a(:second).says 'second'
		#    an(:other).says 'other'
		#  end
		#
		#  builder.sentence.should eql('first second other')
		def an(id)
			and_then id
		end
		alias :a :an



		#Allocates a Phrase which will be said first, relative to any existing Phrases.
		#An optional Phrase id can be provided
		#
		#This phrase would of course be preceded by any subsequent first Phrase
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say 'something'
		#    first.say 'say'
		#  end
		#  builder.sentence.should eql('say something')
		#
		#  builder.first.say 'first'
		#  builder.sentence.should eql('first say something')
		def first(id=nil)
			ordered and_then(id), :first
		end

		#Allocates a Phrase which will be said last, relative to any existing Phrases.
		#An optional Phrase id can be provided
		#
		#This phrase would of course be followed by any subsequent last Phrase
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    last.say 'said'
		#    say 'something'
		#  end
		#  builder.sentence.should eql('something said')
		#
		#  builder.last.say 'last'
		#  builder.sentence.should eql('something said last')
		def last(id=nil)
			ordered and_then(id), :last
		end
		alias :lastly :last

		#Allocates a Phrase which will be said anywhere.
		#It's position will be random (though not first or last, except when there is no alternative).
		#The Phrase will only appear once; you may want to make the Phrase recur as well
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    say 'top'
		#    say 'here'
		#    say 'there'
		#    say 'bottom'
		#  end
		#  builder.anywhere.say 'anywhere'
		#
		#  words = builder.words
		#  words.should have(5).words
		#  words.find_all {|word| word == 'anywhere'}.should have(1).word
		#
		#  builder.it.recurs(2)
		#
		#  words = builder.words
		#  words.should have(6).words
		#  words.find_all {|word| word == 'anywhere'}.should have(2).word
		def anytime(id=nil)
			add_id id
			@phrases << AnytimePhrase.new(self, id)
			ordered self.phrase, :anytime
		end
		alias :anywhere :anytime

		#Allocates a phrase which is said before another Phrase.
		#The resulting words are inserted immediately before the referenced Phrase.
		#
		#This phrase would of course be preceded by any subsequent before Phrase referenced against the same id.
		#Think of it as adding layers to an onion.
		#
		#If the referenced Phrase is never said, due to conditionals / odds / etc, the dependent Phrase will not be said.
		#This of course cascades throughout the dependency chain.
		#
		#The referenced Phrase must exist, by id.
		#However, that is not checked until execution (eg. not during build).
		#You can test your completed Builder using the validate method.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    an(:always).says 'always'
		#    a(:sometimes).says('sometimes').if {|context| context.builder[:sometimes] == true }
		#    before(:always).say 'before-always'
		#    before(:sometimes, :depends).say 'before-sometimes'
		#    before(:depends).say 'depends'
		#  end
		#
		#  builder.sentence.should eql('before-always always')
		#
		#  builder[:sometimes] = true
		#
		#  builder.sentence.should eql('before-always always depends before-sometimes sometimes')
		def before(ref, id=nil)
			depends and_then(id), :before, ref
		end

		#Allocates a phrase which is said after another Phrase.
		#The resulting words are inserted immediately after the referenced Phrase.
		#
		#This phrase would of course be followed by any subsequent after Phrase referenced against the same id.
		#Think of it as adding layers to an onion.
		#
		#If the referenced Phrase is never said, due to conditionals / odds / etc, the dependent Phrase will not be said.
		#This of course cascades throughout the dependency chain.
		#
		#The referenced Phrase must exist, by id.
		#However, that is not checked until execution (eg. not during build).
		#You can test your completed Builder using the validate method.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    an(:always).says 'always'
		#    a(:sometimes).says('sometimes').if {|context| context.builder[:sometimes] == true }
		#    after(:always).say 'after-always'
		#    after(:sometimes, :depends).say 'after-sometimes'
		#    after(:depends).say 'depends'
		#  end
		#
		#  builder.sentence.should eql('always after-always')
		#
		#  builder[:sometimes] = true
		#
		#  builder.sentence.should eql('always after-always sometimes after-sometimes depends')
		def after(ref, id=nil)
			depends and_then(id), :after, ref
		end


		#A shorthand method for and_then.say .
		#A new Phrase is allocated (without an id), and then Phrase#say method is invoked with the arguments provided.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    says 'word'
		#    say :symbol
		#    say { 'lambda' }
		#  end
		#  builder.should have(3).phrases
		#  builder.sentence.should eql('word symbol lambda')
		def say(*args, &block)
			and_then.say *args, &block
		end
		alias :says :say

		#A shorthand method for phrase.or .
		#The Phrase#or method is invoked against the current Phrase with the arguments provided.
		#
		#An Error will be raised if there is no current Phrase.
		#It's an easy condition to recover from, but it's bad use of the syntax.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    says 'word'
		#    alternately.says :symbol
		#  end
		#  builder.or.say { 'lambda' }
		#
		#  builder.should have(1).phrases
		#  builder.phrase.should have(3).instructions
		#  %w{ word symbol lambda}.include?(builder.sentence).should be_true
		def alternately(*args, &block)
			raise Error, "there is no active phrase.  start one with 'say'" unless self.phrase
			self.phrase.or *args, &block
		end
		alias :or :alternately



		#Iterates through each of the words resulting from execution of the Builder.
		#
		#An optional Hash of Context data can be provided.
		#It is merged into Context#data before the Builder is executed
		def each_word(data=nil)
			#	from our words
			self.words(data).each {|word| yield word }
		end
		alias :each :each_word

		#Returns the array of words resulting from execution of the Builder.
		#
		#An optional Hash of Context data can be provided.
		#It is merged into Context#data before the Phrase rules are executed
		#
		#An optional block can be provided.
		#It will be invoked before the Phrase rules are executed
		#The block can either take no arguments, or a Context.
		#
		#All Phrase rules are applied.
		#Each word in the Array is a String.
		#The resulting Array is flattened (vs. any Array hierarchies in the ruleset)
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    says 'word'
		#    say :symbol, [:with, :hierarchy]
		#    say { 'lambda' }
		#  end
		#  builder.words.should eql(%w{ word symbol with hierarchy lambda })
		def words(data=nil, &block)
			#	words from a sequencer
			#		pass on the context data
			#		pass on the block, to pull in the context
			#	a new Sequencer each time
			#	TODO: optimize
			#		dirty flag is hard since phrases is exposed
			#		hashsum?  clone of last known phrases PLUS dirty flag?
			self.to_sequencer.words data, &block
		end
		alias :to_a :words

		#Returns the composite sentence resulting from execution of the Builder.
		#It's really just a shortcut for words.join .
		#
		#An optional separator String can be provided.
		#The default separator is a single space
		#
		#An optional Hash of Context data can be provided.
		#It is merged into Context#data before the Phrase rules are executed
		#
		#An optional block can be provided.
		#It will be invoked before the Phrase rules are executed
		#The block can either take no arguments, or a Context.
		#
		#Examples:
		#  builder = MadderLib::Builder.new do
		#    says 'word'
		#    say :symbol, [:with, :hierarchy]
		#    say { 'lambda' }
		#  end
		#  builder.sentence.should eql('word symbol with hierarchy lambda')
		def sentence(*args, &block)
			#	argument scan
			sep, data = ' ', nil
			args.each do |arg|
				if String === arg
					#	separator
					sep = arg
				elsif Hash === arg
					#	context data
					data = arg
				end
			end

			self.words(data, &block).join(sep)
		end
		alias :to_s :sentence




		def to_sequencer #:nodoc:
			#	general ordering
			sequence = []
			map = {}
			@phrases.each do |phrase|
				sequence << phrase unless self.ordered?(phrase) || self.depends?(phrase)
				map[phrase.id] = phrase if phrase.id
			end

			#	specified ordering
			#	anytimes
			anytimes = []
			@ordered.each do |o|
				case o.type
					when :first
						#	before all other firsts
						sequence.unshift o.phrase
					when :last
						#	after all other lasts
						sequence.push o.phrase

					when :anytime
						#	guarantee valid references
						phrase = o.phrase

						[phrase.before, phrase.after].each do |ref|
							raise Error, "no such phrase : #{ref.inspect}" unless (!ref) || map[ref]
						end
						anytimes << phrase

					else
						raise Error, "unknown ordering : #{o.type.inspect}"
				end
			end

			befores, afters = {}, {}
			@depends.each do |o|
				ref = o.ref
				raise Error, "no such phrase : #{ref.inspect}" unless map[ref]
				case o.type
					when :before
						phrases = befores[ref]
						befores[ref] = (phrases = []) unless phrases
						#	before all other befores
						phrases.unshift o.phrase
					when :after
						phrases = afters[ref]
						afters[ref] = (phrases = []) unless phrases
						#	after all other afters
						phrases.push o.phrase
					else
						raise Error, "unknown dependency : #{o.type.inspect}"
				end
			end

			Sequencer.new(self, sequence, map.keys, {
				:anytime => anytimes, :before => befores, :after => afters,
				:setup => @setup, :teardown => @teardown
			})
		end

		#Validates the Phrase rules in the Builder.
		#If there are any execution-time semantic issues, it will raise the applicable Error
		alias :validate :to_sequencer



		protected

		def add_id(id) #:nodoc:
			if id
				raise Error, "id already exists : #{id.inspect}" if @phrase_ids.include?(id)
				@phrase_ids << id
			end
		end

		ORDERED = Struct.new(:phrase, :type) #:nodoc:
		def ordered(phrase, type) #:nodoc:
			#	simple tuple, but with order retained
			(@ordered ||= []) << ORDERED.new(phrase, type)
			phrase
		end

		def ordered?(phrase) #:nodoc:
			!! @ordered.find {|o| o.phrase == phrase }
		end

		DEPENDS = Struct.new(:phrase, :type, :ref) #:nodoc:
		def depends(phrase, type, ref) #:nodoc:
			#	simple tuple, but with order retained
			(@depends ||= []) << DEPENDS.new(phrase, type, ref)
			phrase
		end

		def depends?(phrase) #:nodoc:
			!! @depends.find {|o| o.phrase == phrase }
		end
	end

end
