module MadderLib
	module Conditional
		module Registry

			module Static
				#	registers a preparation closure for the container
				def add_prepare(&block)
					conditional_prepares << block
				end

				def conditional_prepares
					@conditional_prepares ||= []
				end

				#	registers a test closure for the container
				def add_test(&block)
					raise Error, 'block required' unless block_given?
					conditional_tests << block
				end

				def conditional_tests
					@conditional_tests ||= []
				end
			end



			module Instance
				#	called once per execution
				def prepare(context)
					#	execute all of our registered preparation blocks
					self.class.conditional_prepares.each do |block|
						(block.arity == 1 ? block.call(self) : block.call(self, context))
					end

					if self.methods.include?('instructions')
						#	prepare each instruction
						self.instructions.each {|instruction| instruction.prepare(context) }
					end
				end

				#	returns true if the owner should be used
				def test(context)
					#	find the first failing test closure
					#		it'd be nil if they all pass
					failed = self.class.conditional_tests.find do |block|
						#	first failure stops us
						(! (block.arity == 1 ? block.call(self) : block.call(self, context)))
					end

					failed.nil?
				end
			end
		end
	end
end
