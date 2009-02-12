module SentenceBuilder
	module Conditional
		module Closure

			module Phrase
				# proxy to current instruction
				def assuming(&block)
					self.instruction.assuming &block
				end
				alias :presuming :assuming

				def forbidding(&block)
					self.instruction.forbidding &block
				end
			end



			module Instruction
				def self.included(target)
					#	register a test to test all closures for the instance
					#		return false at the first one that fails
					target.add_test do |instance, context|
						failure = instance.conditional_closures.find do |block|
							#	first failure stops us
							(! (block.arity == 0 ? block.call : block.call(context)))
						end

						failure.nil?
					end
				end


				#	expects that the block will return true for successful test
				def assuming(&block)
					raise Error, 'block required' unless block_given?

					#	set it aside for a lazy day
					conditional_closures << block
					self
				end
				alias :presuming :assuming

				#	expects that the block will return false for successful test
				def forbidding(&block)
					raise Error, 'block required' unless block_given?

					#	wrap in negation
					self.assuming {|context| ! (block.arity == 0 ? block.call : block.call(context)) }
					self
				end



				def conditional_closures
					@conditional_closures ||= []
				end
			end

		end
	end
end
