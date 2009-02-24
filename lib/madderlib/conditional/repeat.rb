module MadderLib
	module Conditional
		#= Recur
		#
		#Introduces support for repeating usage of a Phrase
		module Repeat

			#= Recur::Phrase
			#
			#Introduces support for repeating usage of a Phrase.
			#The Phrase itself is largely uninvolved; it simply uses the repeat logic of its Instruction
			#
			#See:  Recur::Instruction
			module Phrase
				#Adds repetition logic to the current Instruction
				#
				#See:  Instruction#repeat
				def repeat(*args, &block)
					self.instruction.repeat *args, &block
				end
				alias :repeats :repeat
				alias :repeating :repeat
				alias :times :repeat
				alias :while :repeat
			end



			#= Recur::Instruction
			#
			#Introduces support for repeating usage of a Phrase.
			#The Instruction will simply call its own Instruction#speak method until the repetition is over.
			#The sum and total of all those calls becomes the Instruction's resulting words.
			#Note that this is not simply a blind duplication of the results of the first call to speak
			#
			#See:  Recur::Phrase
			module Instruction
				def self.included(target) #:nodoc:
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



				def repeat_speak(context) #:nodoc:
					#	no repetition may be requested
					return pre_repeat_speak(context) unless @repeat_tester

					#	keep speaking until we're told to stop
					composite, count = [], 0

					loop do
						break unless @repeat_tester.invoke(count, context)

						words = pre_repeat_speak(context)
						break if words.empty?

						composite << words
						count += 1
					end

					#	as if we said it all at once
					composite.flatten
				end



				#Specifies the repetition of this Phrase
				#
				#If provided, the arguments should contain:
				#* a numeric value, which becomes the count
				#* a Range, or two numerics (which define a Range), from which the count is chosen randomly
				#* a Proc / lambda / block / closure, which returns false when the repetition should stop. \
				#The block can either take (a) no arguments, (b) the repetition count, or; (c) the count <i>and</i> a Context.
				#
				#A repetition count of 0 will exclude the Phrase from the Builder result
				#
				#A repetition always ends when any Instruction returns an empty set of words.
				#Processing will skip to the next Phrase, even if it could repeat again.
				#This is due to the fact that Instruction#speak is called each time, which could provide different results
				#
				#Examples:
				#  builder = madderlib do
				#    say(:twice).times(2)
				#    say(:couple).repeats(1, 2)
				#    say(:thrice).while {|count| count < 3 }
				#  end
				#
				#  words = builder.words
				#  words.find_all {|word| word == 'twice' }.should have(2).items
				#  words.find_all {|word| word == 'thrice' }.should have(3).items
				#  count = words.find_all {|word| word == 'couple' }.size
				#  (count >= 1 && count <= 2).should be_true
				def repeat(*args, &block)
					#	build a tester, set it aside
					@repeat_tester = Helper::TestBlock.new *args, &block
					self
				end
				alias :repeats :repeat
				alias :repeating :repeat

				#Specifies the repetition of this Phrase using arguments
				#
				#This is syntactic sugar, but also does not accept a block
				#
				#See:  repeat
				def times(*args)
					repeat *args
				end

				#Specifies the repetition of this Phrase using a block
				#
				#This is syntactic sugar, but also does not accept numeric arguments
				#
				#See:  repeat
				def while(&block)
					repeat &block
				end
			end

		end
	end
end
