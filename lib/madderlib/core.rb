module MadderLib
	#= Error
	#
	#A Module-specific Exception class
	#
	#--
	# i would have called it MadderLib::Exception
	# except that i don't know how to access Kernel::Exception within the initialize logic
	#++
	class Error < Exception
		#The propagated cause of this Exception, if appropriate
		attr_reader :cause

		#Constructed with a message and an optional 'causing' Exception.
		#
		#If no message is passed -- eg. only an Exception -- then this Error inherits its message.
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



	#= KernelMethods
	#
	#A Module containing MadderLib methods which are injected into the Kernel scope / namespace.
	#Requiring the gem has the side-effect of injecting these methods.
	module KernelMethods
		#A proxy for MadderLib::Builder.new .
		#It returns a constructed Builder.
		#
		#The resulting Builder is automatically added to the active Grammar.
		#The active grammar can be accessed via madderlib_grammar .
		#
		#Please see MadderLib::Builder for extensive examples of how a Builder itself is put to use
		#
		#Examples:
		#  builder = madderlib do
		#    say 'no id'
		#  end
		#  madderlib_grammar.builders.include?(builder).should be_true
		#  madderlib_grammar.builder_map.values.include?(builder).should_not be_true
		#
		#  builder = madderlib :id do
		#    say 'has id'
		#  end
		#  madderlib_grammar.builders.include?(builder).should be_true
		#  madderlib_grammar.builder_map.values.include?(builder).should be_true
		def madderlib(*args, &block)
			builder = Builder.new *args
			madderlib_grammar.add builder

			builder.extend &block
		end

		#A proxy for MadderLib::Grammar.get_instance .
		#It returns the active Grammar
		#
		#See:  madderlib
		def madderlib_grammar
			#	the current instance we're working with
			Grammar.get_instance
		end
	end



	#= Grammar
	#
	#A class for registering MadderLib Builders.
	#
	#It is intended to help de-couple Ruby scripts which generate Builders from those which use them.
	class Grammar
		class << self
			#Constructs a new Grammar instance
			#
			#The new instance becomes the active Grammar, as accessible from get_instance
			#
			#Examples:
			#  current = MadderLib::Grammar.new_instance
			#  current.should have(0).builders
			#  current.should equal(MadderLib::Grammar.get_instance)
			#
			#  one = madderlib { say 'one' }
			#  current.should have(1).builders
			#  current.builders.include?(one).should be_true
			#
			#  fresh = MadderLib::Grammar.new_instance
			#  fresh.should equal(MadderLib::Grammar.get_instance)
			#
			#  two = madderlib { say 'two' }
			#  fresh.should have(1).builders
			#  fresh.builders.include?(two).should be_true
			#
			#  current.should_not equal(MadderLib::Grammar.get_instance)
			#  current.builders.include?(two).should_not be_true
			def new_instance
				@instance = self.new
			end

			#Returns the active Grammar instance
			#
			#If no such Grammar exists, a new one is created
			#
			#See:  new_instance
			def get_instance
				@instance ||= new_instance
			end
		end

		#An Array of all Builders in the Grammar
		attr_reader :builders
		#A Hash of all the Builders in the Grammar which have an id
		attr_reader :builder_map

		#Constructs a new Grammar
		def initialize
			@builders = []
			@builder_map = {}

			#	randomness
			srand(Time.now.to_i)
		end

		#Adds a Builder to the Grammar.
		#
		#How this is done depends on the arguments passed
		#* if an existing Builder is provided, it is added to the Grammar (as-is)
		#* if nothing is provided, then a new Builder is constructed (without any id)
		#* otherwise, any argument passed is treated as the id for a newly-constructed Builder
		#
		#If a block is provided, and a Builder is constructed, that block is leveraged <i>a la</i> Builder#extend
		#
		#Examples:
		#  grammar = MadderLib::Grammar.new_instance
		#
		#  builder = madderlib { say 'exists' }
		#  x = grammar.add(builder)
		#  x.should equal(builder)
		#  grammar.should have(1).builders
		#  grammar.builder_map.should have(0).keys
		#
		#  builder = grammar.add { say 'no id' }
		#  grammar.should have(2).builders
		#  grammar.builder_map.should have(0).keys
		#  builder.sentence.should eql('no id')
		#
		#  builder = grammar << :id
		#  grammar.should have(3).builders
		#  grammar.builder_map.values.include?(builder).should be_true
		#  builder.sentence.should eql('')
		def add(*args, &block)
			builder = args.first

			case builder
				when Builder
					#	leave it alone
				when nil
					#	new, with block dispatched
					builder = Builder.new &block
				else
					#	new, assume the arg is an ID
					builder = Builder.new args.first, &block
			end

			unless @builders.include?(builder)
				@builders << builder

				#	an id is not required
				id = builder.id
				(@builder_map[id] = builder) if id
			end

			builder
		end
		alias :<< :add

		#Provides convenient access to the Builder map (builder_map).
		#
		#Examples:
		#  grammar = MadderLib::Grammar.new_instance
		#
		#  builder = grammar.add(:id) { say 'has id' }
		#  grammar[:id].should equal(builder)
		def [](key)
			@builder_map[key]
		end

		#Freezes, and closes / completes, the current Grammar
		#
		#The Grammar becomes immutable.
		#As a side-effect, if it is the current Grammar, a new_instance is created and used from this point forwards
		def freeze
			super

			#	deep freeze
			[@builders, @builder_map].each {|o| o.freeze }

			if self.class.get_instance == self
				#	we can no longer be the current Grammar
				self.class.new_instance
			end
		end
		alias :close :freeze
		alias :complete :freeze
	end
end


#	inject into the Kernel
include MadderLib::KernelMethods
