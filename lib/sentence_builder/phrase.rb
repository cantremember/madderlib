module SentenceBuilder
	class Phrase
		attr_reader :id, :instructions

		def initialize(id=nil, *args, &block)
			@id = id
			@instructions = []

			#	don't start out with an empty instruction
			say *args, &block unless (args.empty?) && (! block_given?)
		end

		def say(*args, &block)
			#	allocate new
			@instructions << Instruction.new(self, *args, &block)
			self
		end
		alias :says :say

		def or
			#	syntactic sugar
			self
		end

		def nothing
			#	say nothing
			say
		end
	end



	class AnytimePhrase < Phrase
		def initialize(*args)
			super

			#	assume once, and no position limits
			@times = 1
		end

		def repeating(*args, &block)
			#	if we get a block, use it!
			@repeat_logic = block
			if @repeat_logic
				raise 'block AND arguments provided, remove one or the other' unless args.empty?
				raise 'block arity should be 0 or 1 (count)' unless (block.arity < 2)
				return
			end

			#	guess we have to work for this
			arg = args.pop

			begin
				if Range === arg
					#	we support that
					how = arg
					arg = args.pop
				elsif arg.integer?
					lower, arg = arg, args.pop

					if arg.integer?
						#	we can make a range from that
						how = Range.new(lower, arg)
					else
						#	just a count
						how = lower
					end
					arg = args.pop
				else
					raise Error, "invalid repeating argument : #{arg.inspect}"
				end
			rescue Error => e
				raise e
			rescue Exception => e
				#	wrap
				raise Error.new("invalid repeating argument : #{arg.inspect}", e)
			end

			#	we will have advanced to the next argument
			case arg
				when :minutes
					#	a temporary hack, for literal Conet building
					if Range === how
						how = Range.new(how.lower * MINUTE_MULTIPLIER, how.upper * MINUTE_MULTIPLIER)
					else
						how *= MINUTE_MULTIPLIER
					end
				#when :times
				#when nil
				#	all of those are no-op conditions
			end

			#	now we know how
			@repeat_logic = how
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



		class Voter
			attr_reader :instruction, :count

			def initialize(instruction)
				@instruction = instruction
				@count = 0

				logic = @instruction.repeat_logic
				case logic
					when Proc
						@logic = logic
					when Range
						limit = logic.rand
						@logic = lambda { @count < limit }
					else
						limit = rand(logic)
						@logic = lambda { @count < limit }
				end
			end

			def vote(context)
				#	!!!
				#		before
				#		after
				(@logic.arity == 0 ? @logic.call : @logic.call(context) )
			end

			def touch
				@count += 1
			end
		end



		#	- - - - -
		private

		MINUTE_MULTIPLIER = 3
	end



	class Instruction
		attr_reader :phrase, :words

		def initialize(phrase, *args, &block)
			@phrase = phrase

			@words = []
			args.each {|arg| @words << arg unless arg.nil? }
			@words << block if block_given?
		end

		def empty?
			@words.empty?
		end
	end



	class Context
		attr_reader :repeats
	end
end
