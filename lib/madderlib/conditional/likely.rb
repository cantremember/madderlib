module MadderLib
	module Conditional
		module Likely
			DEFAULT_WEIGHT = 1

			module Phrase
				def self.included(target)
					#	before each run, we need to prepare ourself
					target.add_prepare do |phrase, context|
						#	no point in likelihood when there's only one choice
						unless phrase.instructions.size < 2
							weights = []
							phrase.instructions.each do |instruction|
								#	put on a default weight if no other option
								while (tester = instruction.conditional_likely_tester).nil?
									instruction.likely(DEFAULT_WEIGHT)
								end

								weight = tester.to_i(context)
								raise Error, 'invalid weight for instruction : #{instruction.words}' unless weight
								weights << weight
							end
#debugger if phrase.builder.id == :split_3_2_1

							#	easy distributions
							total = 0
							Range.new(0, weights.size - 1).each do |index|
								weight, instruction = weights[index], phrase.instructions[index]

								state = context.state(instruction)
								state[:likely_lower] = total
								state[:likely_upper] = (total += weight)
							end

							#	choose a random value
							state = context.state(phrase)
							state[:likely_total] = total
							state[:likely_count] = rand(total)
						end
					end
				end



				# proxy to current instruction
				def likely(*args, &block)
					self.instruction.likely *args, &block
				end
				alias :weight :likely
				alias :weighted :likely
				alias :weighing :likely
			end



			module Instruction
				def self.included(target)
					#	register a test to test all allowances for the instruction
					#		return false at the first one that fails
					target.add_test do |instruction, context|
						phrase = instruction.phrase
						test = true

						state = context.state(phrase)
						total = state[:likely_total]
						count = state[:likely_count]

						#	will only have a count if there's likelihood calc required
						if count
							state = context.state(instruction)
							lower = state[:likely_lower]
							upper = state[:likely_upper]

							test = (count >= lower) && (count < upper)

							if test && phrase.respond_to?(:recurs?) && phrase.recurs?
								#	set it up for the next recurrance
								#		we don't want the same thing over and over again
								state[:likely_count] = rand(total)
							end
						end

						test
					end
				end



				def likely(*args, &block)
					#	build a tester, set it aside
					@likely_tester = Helper::TestBlock.new *args, &block
					self
				end
				alias :weight :likely
				alias :weighted :likely



				def conditional_likely_tester
					@likely_tester
				end
			end

		end
	end
end
