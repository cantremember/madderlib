module SentenceBuilder
	#= Error
	#
	#A Module-specific Exception class
	#
	#--
	# i would have called it SentenceBuilder::Exception
	# except that i don't know how to access Kernel::Exception within the initialize logic
	#++
	class Error < Exception
		#The propagated cause of this Exception, if appropriate
		attr_reader :cause

		#Provide a message and an optional 'causing' Exception.
		#
		#If no message is passed -- eg. only an Exception -- then this Exception inherits its message.
		def initialize(message, cause=nil)
			if (Exception === message)
				super message.to_s
				@cause = message
			else
				super message
				@cause = cause
			end
		end
	end



	module KernelMethods
		def sentence_builder(*args, &block)
			builder = Builder.new *args
			sentence_grammar.add builder

			builder.extend &block
		end

		def sentence_grammar
			#	the current instance we're working with
			Grammar.get_instance
		end
	end



	class Grammar
		class << self
			def new_instance
				@instance = self.new
			end
			def get_instance
				@instance ||= new_instance
			end
		end

		attr_reader :builders, :builder_map

		def initialize
			@builders = []
			@builder_map = {}
		end

		def add(builder)
			unless @builders.include?(builder)
				@builders << builder

				#	an id is not required
				id = builder.id
				(@builder_map[id] = builder) if id
			end
		end
		alias :<< :add

		def close
			self.class.new_instance
		end
		alias :complete :close
	end
end


#	inject into the Kernel
include SentenceBuilder::KernelMethods
