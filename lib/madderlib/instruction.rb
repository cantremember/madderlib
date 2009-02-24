module MadderLib
	#= Instruction
	#
	#A specific instruction within a MadderLib ruleset.
	#
	#A Phrase is comprised of one or more Instructions.
	#Each Instruction contains the logic necessary to produce the result for the Phrase
	#
	#Typical 'words' that can appear in an Instruction are:
	#* a String
	#* a Symbol
	#* a Proc / lambda / block / closure
	#* another Builder
	#* an Array of the above
	#
	#The logic by which these types are resolved is described within wordify .
	#
	#An Instruction also supports:
	#* repetition, via Conditional::Repeat
	#* conditional usage, via Conditional::Allowed
	#* proportionate usage, via Conditional::Likely
	class Instruction
		class << self
			include Conditional::Registry::Static
		end
		include Conditional::Registry::Instance

		#A refererence to the Phrase which contains this Instruction
		attr_reader :phrase
		#An Array of the words produced by this Instruction.
		#The term 'word' is used very loosely here; they are simply the Objects provided during construction
		attr_reader :words



		#Constructs a new Instruction
		#
		#The containing Phrase is required.
		#
		#Any number of arguments may be provided, and they become the Instruction's words.
		#An optional block can be provided, and if so, it is also treated as a word (since a Proc is considered a valid 'word')
		def initialize(phrase, *args, &block)
			@phrase = phrase
			@words = args
			@words << block if block_given?
		end



		#A proxy for phrase.alternately .
		#The Phrase#alternately method is invoked against the Instruction's containing Phrase with the arguments provided
		def alternately(*args, &block)
			#	proxy to the phrase
			self.phrase.or *args, &block
		end
		alias :or :alternately



		#Generates the list of words for this Instruction.
		#
		#This method returns a flattened Array of all the Instruction's words, resolved as of 'now'.
		#All blank and nil values are removed from the Array
		#
		#A thorough description of how words are resolved can be find in the wordify method
		#
		#Example:
		#  builder = madderlib do
		#    say nil
		#    say ''
		#  end
		#  builder.words.should eql([])
		#
		#  builder = madderlib do
		#    say 'one'
		#    say :two
		#    say 3
		#  end
		#  builder.words.should eql(%w{ one two 3 })
		#
		#  builder = madderlib do
		#    say []
		#    say [ nil, 'one' ]
		#    say [ :two, [ '', 3 ]]
		#  end
		#  builder.words.should eql(%w{ one two 3 })
		#
		#  builder = madderlib do
		#    say madderlib { say 'one' }
		#    say madderlib {
		#      say madderlib { say :two }
		#      say madderlib { say 3 }
		#    }
		#  end
		#  builder.words.should eql(%w{ one two 3 })
		#
		#  words = [ 'one', lambda { :two }, madderlib { say 3 } ]
		#  builder = madderlib do
		#    say { words.shift }.repeat { ! words.empty? }
		#  end
		#  builder.words.should eql(%w{ one two 3 })
		def speak(context)
			#	wordify everything, and strip out blanks & nils
			spoken = self.class.wordify(words, context)
			spoken.find_all {|word| word && (! word.empty?) }
		end



		include Conditional::Allowed::Instruction
		include Conditional::Repeat::Instruction
		include Conditional::Likely::Instruction

		#	- - - - -
		protected

		class << self
			#Converts the object passed into a 'word', according to the following rules:
			#
			#* <code>nil</code> => nil
			#* <code>String</code> => itself (blank Strings also)
			#* <code>Proc / lambda / block / closure</code> => the result of invoking the block. \
			#The block can either take no arguments, or a Context. \
			#Please note that resolution of the Proc's scoped variables (etc.) occurs only at the time that wordify is invoked!
			#* <code>Builder</code> => the result of Builder#words, which will be an Array
			#* <code>Array</code> => a flattened Array of the each element, as converted via wordify
			#
			#Anything other Object type is converted to a string via Object#to_s.
			#
			#See:  speak
			def wordify(source, context)
				#	our own dogfood
				if Builder === source
					#	build the words
					#		pull back and track the context
					#		we know they'll be Strings, so no need for recursion
					return source.words {|sub_context| context.add_context sub_context }
				end

				while (Proc === source)
					#	evaluate, then wordify the result
					#		this addresses the Proc-returns-a-Proc condition
					#		it's a corner case
					source = Context.invoke(source, context)
				end

				if (Array === source)
					#	recursive parsing
					#		plus flattening!
					source = source.inject([]) do |a, word|
						word = wordify(word, context)

						if Array === word
							a += word
						else
							a << word
						end

						a
					end
				elsif source && ! (String === source)
					#	don't stringify nil
					source = source.to_s
				end

				source
			end
		end
	end
end
