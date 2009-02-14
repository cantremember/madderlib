module MadderLib
	module Conditional
		module Recur

			module Phrase
				def self.included(target)
					#	before each run, we need to prepare ourself
					target.add_prepare do |phrase, context|
						unless phrase.conditional_recur_tester
							#	we'll only run once if not told otherwise
							phrase.recur 1
						end

						#	we must retain state (the number of times called)
						#	and a consistent block for testing
						state = context.state(phrase)
						state[:recur_block] = phrase.conditional_recur_tester.block
						state[:recur_count] = 0
					end

					#	register a test for recurrance
					target.add_test do |phrase, context|
						#	where we at now
						state = context.state(phrase)
						block = state[:recur_block]
						count = state[:recur_count]
						state[:recur_count] = count + 1

						#	the block call returns the result of our test
						case block.arity
							when 0
								block.call
							when 1
								block.call(count)
							else
								block.call(count, context)
						end
					end
				end



				def recur(*args, &block)
					#	build a tester, set it aside
					@recur_tester = Helper::TestBlock.new *args, &block
					self
				end
				alias :recurs :recur
				alias :recurring :recur

				def recurs?(context=MadderLib::Context::EMPTY)
					!! (conditional_recur_tester && (conditional_recur_tester.to_i(context) > 1))
				end



				def conditional_recur_tester
					@recur_tester
				end
			end



			module Instruction
				#	not impacted
				#		the Phrase repeats, not the Instruction
				#	we could proxy the recur back to the active phrase
				#		but that would be confusing
				#		you should only set up recurrence once; it's singleton to the phrase
			end

		end
	end
end
