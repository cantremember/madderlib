module SentenceBuilder
	class Phrase
		class << self
			include Conditional::Registry::Static
		end
		include Conditional::Registry::Instance

		attr_reader :builder, :id, :instructions



		def initialize(builder, id=nil, *args, &block)
			@builder, @id = builder, id
			@instructions = []

			#	don't start out with an empty instruction
			say *args, &block unless (args.empty?) && (! block_given?)
		end

		def say(*args, &block)
			#	allocate new
			@instructions << Instruction.new(self, *args, &block)

			if @or_likely
				#	retro-apply the likelihood from the 'or' operation
				args, block = @or_likely
				#!!!	self.instruction.likely *args, &block
				@or_likely = nil
			end

			self
		end
		alias :says :say

		def or(*args, &block)
			#	hold onto these until we say something
			@or_likely = [args, block]
			self
		end

		def nothing
			#	say nothing
			say
		end



		def instruction
			raise Error, 'there is no current Instruction' if @instructions.empty?

			#	whatever our current once is
			@instructions.last
		end



		def speak(context)
			found = nil

			#	should we speak at all?
			if self.test(context)
				#	say the first sensible thing
				found = instructions.find do |instruction|
					instruction.test(context)
				end
			end

			(found ? found.speak(context) : [])
		end



		include Conditional::Allowed::Phrase
		include Conditional::Repeat::Phrase
	end



	class AnytimePhrase < Phrase
		def initialize(*args)
			super
		end



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

		def between(a, b)
			after a
			before b
			self
		end



		include Conditional::Recur::Phrase
	end
end
