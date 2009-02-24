module MadderLib
	module Conditional
		#= Likely
		#
		#Introduces support for proportional selection from multiple Instructions in a given Phrase
		module Likely
			#The default weight for an Instruction, which is 1
			DEFAULT_WEIGHT = 1

			#= Likely::Phrase
			#
			#Introduces support for proportional selection from multiple Instructions in a given Phrase
			#
			#This is a very fancy way of saying 'weighted choices'.
			#Using Phrase#alternately, multiple Instructions can be added to the same Phrase.
			#Each one will either use the DEFAULT_WEIGHT, if not otherwise specified, or:
			#
			#* a numeric value
			#* a Proc / lambda / block / closure which returns a numeric value
			#
			#The weights for all Instructions are totalled prior to each execution of the Builder.
			#A random weight is chosen, and that defines the Instruction to be used
			#
			#See:  Likely::Instruction
			module Phrase
				def self.included(target) #:nodoc:
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
							state[:likely_count] = rand(total) # Range.new(0, total).rand_inclusive
						end
					end
				end



				#Adds proportional logic to the current Instruction
				#
				#See:  Instruction#likely
				def likely(*args, &block)
					self.instruction.likely *args, &block
				end
				alias :weight :likely
				alias :weighted :likely
				alias :weighing :likely
				alias :odds :likely
			end



			#= Likely::Instruction
			#
			#Introduces support for proportional selection from multiple Instructions in a given Phrase
			#
			#See:  Likely::Phrase
			module Instruction
				def self.included(target) #:nodoc:
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



				#Specifies the likelihood of this Instruction being used, compared to its siblings in their Phrase
				#
				#If provided, the arguments should contain:
				#* a numeric value, which becomes the weight
				#* a Range, or two numerics (which define a Range), from which the weight is chosen randomly
				#* a Proc / lambda / block / closure, which returns a numeric value. \
				#The block can either take no arguments, or a Context.
				#
				#See:  Instruction#alternately
				#
				#Examples:
				#  builder = madderlib do
				#    say('parsley').likely(4)
				#    alternately(3).say('sage')
				#    alternately.say('rosemary').weighted(2).or.say('thyme')
				#  end
				#
				#  usage = {}
				#  60.times do
				#    key = builder.sentence
				#    usage[key] = (usage[key] || 0) + 1
				#  end
				#
				#  #  if proportions were accurately reproducible:
				#  #    usage['parsley'].should eql(20)
				#  #    usage['sage'].should eql(15)
				#  #    usage['rosemary'].should eql(10)
				#  #    usage['thyme'].should eql(5)
				def likely(*args, &block)
					#	build a tester, set it aside
					@likely_tester = Helper::TestBlock.new *args, &block
					self
				end
				alias :weight :likely
				alias :weighted :likely
				alias :weighing :likely
				alias :odds :likely



				def conditional_likely_tester #:nodoc:
					@likely_tester
				end
			end

		end
	end
end
