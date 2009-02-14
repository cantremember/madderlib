module MadderLib
	module Conditional
		module Repeat

			module Phrase
				# proxy to current instruction
				def repeat(*args, &block)
					self.instruction.repeat *args, &block
				end
				alias :repeats :repeat
				alias :repeating :repeat
				alias :times :repeat
				alias :while :repeat
			end



			module Instruction
				def self.included(target)
					#	this method won't exist until inclusion
					#		can't mess with it until that point
					#	moreover, can't call the method 'speak'
					#		won't overwrite an existing method
					#		so, we do aliasing to swap
					target.class_eval %q{
						alias :pre_repeat_speak :speak
						alias :speak :repeat_speak
					}
				end



				def repeat_speak(context)
					#	no repetition may be requested
					return pre_repeat_speak(context) unless @repeat_tester

					#	keep speaking until we're told to stop
					composite, count = [], 0
					block = @repeat_tester.block

					loop do
						case block.arity
							when 0
								break unless block.call
							when 1
								break unless block.call(count)
							else
								break unless block.call(count, context)
						end

						words = pre_repeat_speak(context)
						break if words.empty?

						composite << words
						count += 1
					end

					#	as if we said it all at once
					composite.flatten
				end



				def repeat(*args, &block)
					#	build a tester, set it aside
					@repeat_tester = Helper::TestBlock.new *args, &block
					self
				end
				alias :repeats :repeat
				alias :repeating :repeat

				#	syntactic sugar for args
				alias :times :repeat
				#	syntactic sugar for block
				alias :while :repeat
			end

		end
	end
end
