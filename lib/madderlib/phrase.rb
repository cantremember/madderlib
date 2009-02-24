module MadderLib
	#= Phrase
	#
	#A specific phrase within a MadderLib Builder.
	#
	#A Phrase is a collection of one or more Instruction objects.
	#An Instruction is selected, and that becomes the Phrase's result
	#
	#A Phrase supports:
	#
	#* proportioned choice of Instructions, via Conditional::Likely
	class Phrase
		class << self
			include Conditional::Registry::Static
		end
		include Conditional::Registry::Instance

		#A refererence to the Builder which contains this Phrase
		attr_reader :builder
		#The (optional) id of the Phrase
		attr_reader :id
		#An Array of the Instructions used by this Phrase
		attr_reader :instructions



		#Constructs a new Phrase
		#
		#The containing Phrase is builder.
		#
		#An optional id can be provided.
		#The id is particularly useful in the case of:
		#* relative positioning, via Builder#before or Builder#after
		#* conditional usage, via Conditional::Allowed#assuming , etc.
		#* positioning ranges, via AnywherePhrase#between , etc.
		#
		#Any number of arguments may be provided, and they are dispatched to the say method.
		#An optional block can be provided, and if so, it is also dispatched to say.
		def initialize(builder, id=nil, *args, &block)
			@builder, @id = builder, id
			@instructions = []

			#	don't start out with an empty instruction
			say *args, &block unless (args.empty?) && (! block_given?)
		end



		#Adds a new Instruction to the Phrase using the provided arguments.
		#
		#All arguments, and any block provided, are used to construct the new Instruction.
		#Any proportion logic which has been cached via a prior call to alternately us applied to the new Instruction
		#
		#See:  Builder#say
		def say(*args, &block)
			#	allocate new
			@instructions << Instruction.new(self, *args, &block)

			if @or_likely
				#	retro-apply the likelihood from the 'or' operation
				args, block = @or_likely
				self.instruction.likely *args, &block unless (args.empty? && block.nil?)
				@or_likely = nil
			end

			self
		end
		alias :says :say

		#Sets aside proportion logic to be used by the next call to the say method.
		#
		#Calling this method is a prelude to adding another optional Instruction via say.
		#All arguments are optional; if none are provided, the default proportions will be assumed.
		#Without any arguments, a call to this method is syntactic sugar.
		#You could call say(...).say(...), but it's not quite as descriptive
		#
		#See:  Builder#alternately
		#
		#Examples:
		#  builder = madderlib do
		#    say('barnard').or.say('bryn mawr')
		#    alternately(2).say('mount holyoke').alternately(2).say('radcliffe')
		#    it.alternately(4).says('smith').or(4).says('vassar')
		#  end
		#  builder.phrase.says('wellesley').or(5).nothing
		#
		#  usage = {}
		#  200.times do
		#    key = builder.sentence
		#    usage[key] = (usage[key] || 0) + 1
		#  end
		#
		#  #  if proportions were accurately reproducible:
		#  #    ['barnard', 'bryn mawr', 'wellesley'].each {|name| usage[name].should eql(10) }
		#  #    ['mount holyoke', 'radcliffe'].each {|name| usage[name].should eql(20) }
		#  #    ['smith', 'vassar'].each {|name| usage[name].should eql(40) }
		#  #    [''].each {|name| usage[name].should eql(50) }
		def alternately(*args, &block)
			#	hold onto these until we say something
			@or_likely = [args, block]
			self
		end
		alias :or :alternately

		#Adds a new Instruction to the Phrase which has no content.
		#The Instruction will always return an empty Array, and thus be omitted from the Builder results
		#
		#This method is provided for proportionate Phrases, where 'nothing' may be a suitable output
		#
		#See:  alternately
		def nothing
			#	say nothing
			say
		end



		#Returns the current Instruction.
		#
		#An Error will be raised if there is no current Instruction.
		#It's an easy condition to recover from, but it's bad use of the syntax.
		def instruction
			raise Error, 'there is no current Instruction' if @instructions.empty?

			#	whatever our current once is
			@instructions.last
		end



		#Generates the list of words for this Phrase
		#
		#This is done by:
		#* choosing a suitable Instruction
		#* invoking Instruction#speak
		#
		#See:  Instruction#speak
		def speak(context)
			found = nil

			#	should we speak at all?
			if self.test(context)
				#	say the first sensible thing
				found = instructions.find do |instruction|
					instruction.test(context)
				end
			end

			if found
				#	track our instructions
				context.instructions << found

				#	now, speak your say (as words)
				found = found.speak(context)
			end
			found || []
		end



		include Conditional::Allowed::Phrase
		include Conditional::Repeat::Phrase
		include Conditional::Likely::Phrase
	end



	#= AnytimePhrase
	#
	#A Phrase constructed by Builder#anywhere
	#
	#Beyond what a standard Phrase can do, an AnytimePhrase can specify:
	#
	#* the range of positions where it can be inserted into the Builder result
	#* recurring usage, via Conditional::Recur .\
	#This is <i>not</i> the same as having a repeating Instruction. \
	#The Phrase recurrance indicates how many times it is resolved and inserted into the Builder result. \
	#For example, a recurring Phrase can contain a repeating Instruction.
	class AnytimePhrase < Phrase
		def initialize(*args)
			super
		end



		#States that this Phrase should only appear before the referenced Phrase, by id
		#
		#If the referenced Phrase does not appear in the Builder result, it can appear anywhere
		#
		#Examples:
		#  flag = true
		#  builder = madderlib do
		#    say 'top'
		#    also(:limit).say('middle').if { flag }
		#    say 'bottom'
		#
		#    anywhere.say('hello').before(:limit)
		#  end
		#
		#  10.times do
		#    words = builder.words
		#    words.index('hello').should eql(1)
		#  end
		#
		#  flag = false
		#  10.times do
		#    words = builder.words
		#    (words.index('hello') < 2).should be_true
		#  end
		def before(ref=nil)
			if ref
				#	settter
				@before = ref
				self
			else
				#	getter
				@before
			end
		end

		#States that this Phrase should only appear before the referenced Phrase, by id
		#
		#If the referenced Phrase does not appear in the Builder result, it can appear anywhere
		#
		#Examples:
		#  flag = true
		#  builder = madderlib do
		#    say 'top'
		#    also(:limit).say('middle').if { flag }
		#    say 'bottom'
		#
		#    anywhere.say('hello').after(:limit)
		#  end
		#
		#  10.times do
		#    words = builder.words
		#    words.index('hello').should eql(2)
		#  end
		#
		#  flag = false
		#  10.times do
		#    words = builder.words
		#    (words.index('hello') > 0).should be_true
		#  end
		def after(ref=nil)
			if ref
				#	settter
				@after = ref
				self
			else
				#	getter
				@after
			end
		end

		#A shorthand for expression both after and before limits
		#
		#The first argument is for after, the second is for before
		#
		#Examples:
		#  builder = madderlib do
		#    say 'top'
		#    also(:upper).say('upper')
		#    also(:lower).say('lower')
		#    say 'bottom'
		#
		#    anywhere.say('hello').between(:upper, :lower)
		#  end
		#
		#  10.times do
		#    words = builder.words
		#    words.index('hello').should eql(2)
		#  end
		def between(a, b)
			after a
			before b
			self
		end



		include Conditional::Recur::Phrase
	end
end
