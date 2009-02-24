module MadderLib
	module Conditional
		#= Recur
		#
		#Introduces support for recurrant usage of a Phrase
		module Recur

			#= Recur::Phrase
			#
			#Introduces support for recurrant usage of a Phrase.
			#This is particularly useful for an AnywherePhrase, whose position is randomly chosen.
			#If it has a recurrence, it may appear multiple times.
			#All of this is independent of whatever Instructions are contained within the Phrase
			module Phrase
				def self.included(target) #:nodoc:
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
						#		we buffered the block, but want to invoke it conveniently
						phrase.conditional_recur_tester.invoke(count, context, &block)
					end
				end



				#Specifies the recurrance of this Phrase
				#
				#If provided, the arguments should contain:
				#* a numeric value, which becomes the count
				#* a Range, or two numerics (which define a Range), from which the count is chosen randomly
				#* a Proc / lambda / block / closure, which returns false when the recurrance should stop. \
				#The block can either take (a) no arguments, (b) the recurrance count, or; (c) the count <i>and</i> a Context.
				#
				#A recurrance count of 0 will exclude the Phrase from the Builder result
				#
				#A recurrance always ends when any Instruction returns an empty set of words.
				#Processing will skip to the next Phrase, even if more recurrances are available
				#
				#Examples:
				#  builder = madderlib do
				#    say(:start)
				#    say(:end)
				#    anytime.recurring(2).say(:any)
				#    anytime.recurring {|count| count < 2 }.say(:also)
				#  end
				#
				#  words = builder.words
				#  words.find_all {|word| word == 'any' }.should have(2).items
				#  words.find_all {|word| word == 'also' }.should have(2).items
				def recur(*args, &block)
					#	build a tester, set it aside
					@recur_tester = Helper::TestBlock.new *args, &block
					self
				end
				alias :recurs :recur
				alias :recurring :recur

				#Returns true if the Phrase can recur.
				#By default, the recurrance count is 1, in which case this method returns false
				def recurs?(context=MadderLib::Context::EMPTY)
					!! (conditional_recur_tester && (conditional_recur_tester.to_i(context) > 1))
				end



				def conditional_recur_tester #:nodoc:
					@recur_tester
				end
			end



			module Instruction #:nodoc:
				#	not impacted
				#		the Phrase repeats, not the Instruction
				#	we could proxy the recur back to the active phrase
				#		but that would be confusing
				#		you should only set up recurrence once; it's singleton to the phrase
			end

		end
	end
end
