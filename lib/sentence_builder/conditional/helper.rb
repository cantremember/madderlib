module SentenceBuilder
	module Conditional
		module Helper

			class CountTester
				def initialize(*args, &block)
					if block
						#	if we get a block, use it!
						raise Error, 'block AND args provided, requires one or the other' if (args && (! args.empty?))
						raise Error, 'block arity should be 0; 1 (count) or; 2 (count, Context)' if (block.arity > 2)

						#	it will remain unchanging
						@block = block
					else
						#	leave the originals alone
						args = args.clone

						begin
							#	how does it start?
							arg = args.shift

							if Range === arg
								#	we received a Range
								@range = arg
							elsif arg.integer?
								upper = args.first
								if upper && upper.respond_to?(:integer?) && upper.integer?
									#	we can make a Range from that
									@range = Range.new(arg, args.shift)
								else
									#	just a count
									@limit = arg
								end
							else
								raise Error, "invalid count test argument : #{arg.inspect}"
							end
						rescue Error => e
							raise e
						rescue Exception => e
							#	wrap
							raise Error.new("invalid count test argument : #{arg.inspect}", e)
						end

						#	beyond that, is there a unit?
						#		we deal with all of that during build
						@units = args.shift
					end
				end



				def block
					if @block
						#	the block will do its own testing
						@block
					elsif @range
						#	we'll stop somewhere in that range
						limit = unitize(@range.rand)
						lambda {|count| count < limit }
					elsif @limit
						limit = unitize(@limit)
						lambda {|count| count < limit }
					else
						#	never will succeed
						FALSE
					end
				end



				#	- - - - -
				protected

				FALSE = lambda { false }
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
