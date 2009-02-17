module MadderLib
	class Instruction
		class << self
			include Conditional::Registry::Static
		end
		include Conditional::Registry::Instance

		attr_reader :phrase, :words



		def initialize(phrase, *args, &block)
			@phrase = phrase
			@words = []

			args.each do |arg|
				#	skip nil or blank string
				next if arg.nil? || ('' == arg)

				#	don't just wanna do an args.flatten
				if Array === arg
					@words += arg
				else
					@words << arg
				end
			end

			@words << block if block_given?
		end

		def empty?
			@words.empty?
		end



		def alternately(*args, &block)
			#	proxy to the phrase
			self.phrase.or *args, &block
		end
		alias :or :alternately



		def speak(context)
			#	immediately wordify everything
			#		immediate evaluation allows for more custom operations
			#		that way we eliminate the nils before my caller sees them
			words.inject([]) do |a, word|
				word = self.class.wordify(word, context)
				a << word if word
				a
			end
		end



		include Conditional::Allowed::Instruction
		include Conditional::Repeat::Instruction
		include Conditional::Recur::Instruction
		include Conditional::Likely::Instruction

		#	- - - - -
		protected

		class << self
			def wordify(source, context)
				#	our own dogfood
				if Builder === source
					#	build the words
					#		pull back and track the context
					return source.words {|sub_context| context.add_context sub_context }
				end

				if (Proc === source)
					#	evaluate
					source = Context.invoke(source, context)
				elsif (Builder === source)
					source = source
				end

				(String === source ? source : source.to_s)
			end
		end
	end
end
