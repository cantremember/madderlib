module SentenceBuilder
	module Conditional
		module Allowed

			module Phrase
				# proxy to current instruction
				def assuming(*args, &block)
					self.instruction.assuming *args, &block
				end
				alias :presuming :assuming
				alias :if :assuming

				def forbidding(*args, &block)
					self.instruction.forbidding *args, &block
				end
				alias :unless :forbidding
			end



			module Instruction
				def self.included(target)
					#	register a test to test all closures for the instance
					#		return false at the first one that fails
					target.add_test do |instance, context|
						failure = instance.conditional_closures.find do |block|
							#	first failure stops us
							(! Context.invoke(block, context))
						end

						failure.nil?
					end
				end


				#	expects that the block will return true for successful test
				#	id = true if id spoken
				def assuming(id=nil, &block)
					if block
						raise Error, 'block AND id provided, requires one or the other' if id
						Context.validate(block)
					else
						#	true if the id expressed has been spoken
						block = lambda {|context| context.spoken_ids.include?(id) }
					end

					#	set it aside for a lazy day
					conditional_closures << block
					self
				end
				alias :presuming :assuming
				alias :if :assuming

				#	expects that the block will return false for successful test
				#	id = true unless id spoken
				def forbidding(id=nil, &block)
					if block
						raise Error, 'block AND id provided, requires one or the other' if id
						Context.validate(block)

						self.assuming {|context| ! Context.invoke(block, context) }
					else
						#	true unless the id expressed has been spoken
						self.assuming {|context| ! context.spoken_ids.include?(id) }
					end
				end
				alias :unless :forbidding



				def conditional_closures
					@conditional_closures ||= []
				end
			end

		end
	end
end
