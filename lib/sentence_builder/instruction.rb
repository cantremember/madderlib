module SentenceBuilder
	class Instruction
		class << self
			include Conditional::Registry::Static
		end
		include Conditional::Registry::Instance

		attr_reader :phrase, :words



		def initialize(phrase, *args, &block)
			@phrase = phrase

			@words = []
			args.each {|arg| @words << arg unless arg.nil? }
			@words << block if block_given?
		end

		def empty?
			@words.empty?
		end



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
				return source.to_words if Builder === source

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
