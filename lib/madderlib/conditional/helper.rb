module MadderLib
	module Conditional
		module Helper

			class TestBlock
				FALSE = lambda { false }
				ONE = lambda { 1 }

				attr_reader :criteria

				def initialize(*args, &block)
					if block
						#	if we get a block, use it!
						raise Error, 'block AND args provided, requires one or the other' if (args && (! args.empty?))
						raise Error, 'block arity should be 0; 1 (count) or; 2 (count, Context)' if (block.arity > 2)

						#	it will remain unchanging
						@criteria = block
					else
						#	leave the originals alone
						args = args.clone

						begin
							#	how does it start?
							arg = args.shift

							if Range === arg
								#	we received a Range
								@criteria = arg
							elsif arg.respond_to?(:integer?) && arg.integer?
								upper = args.first
								if upper && upper.respond_to?(:integer?) && upper.integer?
									#	we can make a Range from that
									@criteria = Range.new(arg, args.shift)
								else
									#	just a count
									@criteria = arg
								end
							else
								raise Error, "invalid test block argument : #{arg.inspect}"
							end
						rescue Error => e
							raise e
						rescue Exception => e
							#	wrap
							raise e
							raise Error.new("invalid test block argument : #{arg.inspect}", e)
						end

						#	beyond that, is there a unit?
						#		we deal with all of that during build
						@units = args.shift
					end
				end



				def block
					if Proc === @criteria
						#	the block will do its own testing
						@criteria
					elsif Range === @criteria
						#	we'll stop somewhere in that range
						#		note that it's inclusive
						#		if the caller says '2 .. 4', 4 should be a possibility
						limit = unitize(@criteria.rand_inclusive)
						lambda {|count| count < limit }
					elsif @criteria.integer?
						limit = unitize(@criteria)
						lambda {|count| count < limit }
					else
						#	never will succeed
						FALSE
					end
				end

				def invoke(*args, &given_block)
					#	take in a block, or use the internally held one
					#		allows for external buffering
					b = block_given? ? given_block : self.block
					p = args

					if b.arity < 1
						#	how interesting!  arity of -1
						b.call
					else
						#	only as many args as supported
						#		do not worry about shortfall; that'll be a failure
						p.pop while b.arity < p.size
						b.call *p
					end
				end



				def to_i(context)
					value = nil

					if Proc === @criteria
						value = MadderLib::Context.invoke(@criteria, context)
					elsif Range === @criteria
						value = @criteria.max
					elsif @criteria.integer?
						value = @criteria
					end

					#	has to be an integer, by definition
					if value && value.respond_to?(:integer?) && value.integer?
						unitize(value)
					else
						nil
					end
				end



				#	- - - - -
				protected

				MINUTE_MULTIPLIER = 3

				def unitize(limit)
					case @units
						when :minutes, :minute
							#	a crude hack, for literal Conet building
							limit * MINUTE_MULTIPLIER
						when :times, :time
							limit
						else
							limit
					end
				end
			end

		end
	end
end
