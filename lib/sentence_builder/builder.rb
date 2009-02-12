%w{ generator }.each {|lib| require lib }



module SentenceBuilder
	class Builder
		include Enumerable

		attr_reader :id, :phrases, :phrase_ids

		def initialize(id=nil, &block)
			@id = id
			@phrases, @phrase_ids = [], []
			@ordered, @depends = [], []

			self.extend &block if block_given?
			self
		end

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



		def setup(&block)
			Context.validate(block)
			@setup = block
		end

		def teardown(&block)
			Context.validate(block)
			@teardown = block
		end



		#	the current phrase
		def phrase
			@phrases.last
		end
		alias :it :phrase

		#	another phrase, id is optional
		def and_then(id=nil)
			add_id id
			@phrases << Phrase.new(self, id)
			@phrases.last
		end
		alias :and :and_then
		alias :then :and_then
		alias :also :and_then

		#	another phrase, id is required
		#	for semantic sugar
		def an(id)
			and_then id
		end
		alias :a :an
		alias :new :an



		def first(id=nil)
			ordered and_then(id), :first
		end

		def last(id=nil)
			ordered and_then(id), :last
		end
		alias :lastly :last

		def anytime(id=nil)
			add_id id
			@phrases << AnytimePhrase.new(self, id)
			ordered self.phrase, :anytime
		end
		alias :anywhere :anytime

		def before(ref, id=nil)
			#	executes before ref, but only if ref executes
			#	subsequent befores come before previous befores (unshift)
			depends and_then(id), :before, ref
		end

		def after(ref, id=nil)
			#	executes after ref, but only if ref executes
			#	subsequent afters come after previous afters (push)
			depends and_then(id), :after, ref
		end



		def say(*args, &block)
			#	shorthand for 'then say...'
			#		no id is involved
			and_then.say *args, &block
		end
		alias :says :say

		def alternately(*args, &block)
			#	shorthand for 'or say...'
			#	really, it's syntactic sugar
			raise Error, "there is no active phrase.  start one with 'say'" unless self.phrase
			self.phrase.or *args, &block
		end
		alias :or :alternately



		def each_word
			#	from our words
			self.to_words.each {|word| yield word }
		end
		alias :each :each_word

		#	returns the raw contents of the sequencer
		def to_gen
			Generator.new(self.to_sequencer)
		end
		alias :validate :to_gen

		#	returns the words from the sequencer
		def to_words
			a, g = [], self.to_gen
			a << g.next while g.next?
			a
		end
		alias :to_a :to_words

		def to_s(separator=' ')
			self.to_words.join(separator)
		end



		#	- - - - -
		protected

		def add_id(id)
			if id
				raise Error, "id already exists : #{id.inspect}" if @phrase_ids.include?(id)
				@phrase_ids << id
			end
		end

		ORDERED = Struct.new(:phrase, :type)
		def ordered(phrase, type)
			#	simple tuple, but with order retained
			(@ordered ||= []) << ORDERED.new(phrase, type)
			phrase
		end

		def ordered?(phrase)
			!! @ordered.find {|o| o.phrase == phrase }
		end

		DEPENDS = Struct.new(:phrase, :type, :ref)
		def depends(phrase, type, ref)
			#	simple tuple, but with order retained
			(@depends ||= []) << DEPENDS.new(phrase, type, ref)
			phrase
		end

		def depends?(phrase)
			!! @depends.find {|o| o.phrase == phrase }
		end

		def to_sequencer
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
	end
end
