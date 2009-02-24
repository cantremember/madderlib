module MadderLib
	module Conditional
		#= Allowed
		#
		#Introduces support for conditional usage of an Instruction
		module Allowed

			#= Allowed::Phrase
			#
			#Introduces support for conditional usage of an Instruction
			#
			#If a Phrase has no Instructions that can be used, it will return an empty result and be omitted
			#
			#See:  Allowed::Instruction
			module Phrase
				#Adds conditional logic to the current Instruction
				#
				#See:  Instruction#assuming
				def assuming(*args, &block)
					self.instruction.assuming *args, &block
				end
				alias :presuming :assuming
				alias :if :assuming

				#Adds conditional logic to the current Instruction
				#
				#See:  Instruction#forbidding
				def forbidding(*args, &block)
					self.instruction.forbidding *args, &block
				end
				alias :unless :forbidding
			end



			#= Allowed::Instruction
			#
			#Introduces support for conditional usage of an Instruction
			#
			#The conditional logic is evaluated for each separate execution of the Builder.
			#If the conditional returns false, then the Instruction is excluded from use.
			#If it returns true, then the Instruction is still a viable candidate (though other constraints may be applied)
			#
			#See:  Allowed::Phrase
			module Instruction
				def self.included(target) #:nodoc:
					#	register a test to test all allowances for the instruction
					#		return false at the first one that fails
					target.add_test do |instruction, context|
						failure = instruction.conditional_allowances.find do |block|
							#	first failure stops us
							(! Context.invoke(block, context))
						end

						failure.nil?
					end
				end



				#The instruction will only be used if these conditions are true
				#
				#The id of a Phrase can be provided.
				#If so, then the condition tested is:  the reference must have already been added to the Builder's result.
				#This can be identified through Context#spoken
				#
				#Alternately, a custom block can be provided.
				#The block can either take no arguments, or a Context.
				#The Instruction may only be used when that block returns a true (eg. non-false) value
				#
				#Examples:
				#  switch = false
				#  builder = madderlib do
				#    an(:on).says('on').assuming { switch }
				#    an(:off).says('off').if { ! switch }
				#    say('bright').if :on
				#    say('dark').if :off
				#  end
				#
				#  builder.sentence.should eql('off dark')
				#  switch = true
				#  builder.sentence.should eql('on bright')
				def assuming(id=nil, &block)
					if block
						raise Error, 'block AND id provided, requires one or the other' if id
						Context.validate(block)
					else
						#	true if the id expressed has been spoken
						block = lambda {|context| context.spoken_ids.include?(id) }
					end

					#	set it aside for a lazy day
					conditional_allowances << block
					self
				end
				alias :presuming :assuming
				alias :if :assuming

				#The instruction will only be used if these conditions are false.
				#This is the logical opposite of assuming.
				#
				#The id of a Phrase can be provided.
				#If so, then the condition tested is:  the reference must not have been added to the Builder's result.
				#This can be identified through Context#spoken
				#
				#Alternately, a custom block can be provided.
				#The block can either take no arguments, or a Context.
				#The Instruction may only be used when that block returns a false value
				#
				#Examples:
				#  switch = false
				#  builder = madderlib do
				#    an(:on).says('on').forbidding { ! switch }
				#    an(:off).says('off').unless { switch }
				#    say('bright').unless :off
				#    say('dark').unless :on
				#  end
				#
				#  builder.sentence.should eql('off dark')
				#  switch = true
				#  builder.sentence.should eql('on bright')
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



				def conditional_allowances #:nodoc:
					@conditional_allowances ||= []
				end
			end

		end
	end
end
