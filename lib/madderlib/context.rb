module MadderLib
	#= Context
	#
	#A context-holder object for MadderLib sentences.
	#
	#During the execution of a builder, the context is used to retain state for all parties that care about such things.
	#Each execution produces a new context
	#
	#It is a useful tool for providing dynamic logic and data to a completed (eg. 'static') Builder
	class Context
		attr_reader :sequencer #:nodoc:
		#An Array of all Phrases which contributed words.
		#The Phrases are listed in the order that they were executed
		attr_reader :spoken
		#An Array of all Phrases which <i>did not</i> contribute words.
		#A conditional may have failed, or the resulting content was either empty or nil.
		#The Phrases are listed in the order that they were executed
		attr_reader :silent
		#An Array of the ids of all Phrases which contributed words.
		#The ids are listed in the order that their Phrases were executed
		attr_reader :spoken_ids
		#An Array of all Instructions which contributed words, as chosen from their Phrase.
		#The Phrases are listed in the order that they were executed
		attr_reader :instructions
		#A Hash of arbitrary data for the Context.
		#It is reserved for custom developer logic; the Context doesn't consider its data
		attr_reader :data

		#Constructs a new Context.
		#
		#An optional Sequencer can be provided.
		#The Sequencer is intentionally clouded in mystery, since it fulfils no external purpose.
		#It is optional only for mock testing; it is <i>required</i> for Builder execution.
		def initialize(sequencer=nil)
			@sequencer = sequencer
			@spoken, @silent, @spoken_ids = [], [], []
			@instructions, @contexts = [], []
			@state, @data = {}, {}
		end

		#Returns the Builder associated with the Context, via its Sequencer
		def builder
			@sequencer.builder
		end

		#Returns a Hash associated with the key provided.
		#The value returned will not be nil
		#
		#This Hash can be used to store state data through the lifecycle of the Context.
		#
		#Examples:
		#  context = MadderLib::Context.new
		#  state = context.state(:state)
		#  state.should_not be_nil
		#
		#  state[:key] = :value
		#  context.state(:state)[:key].should equal(:value)
		def state(key)
			hash = @state[key]
			@state[key] = hash = {} unless hash
			hash
		end

		#Provides convenient access to the data Hash.
		#
		#Examples:
		#  context = MadderLib::Context.new
		#  context.data[:key] = :value
		#
		#  context[:key].should equal(:value)
		def [](k)
			@data[k]
		end
		def []=(k, v)
			@data[k] = v
		end

		#Returns an Array of all sub-contexts which were generated during Builder execution.
		#These would come from any Builders that were executed as children of their parent Builder.
		#The list will <i>not</i> include self, only its children (etc.).
		#So if the Array is empty, the only the <i>self</i> Context was involved, with no children.
		#
		#The sub-contexts will be returned as an Array.
		#If <code>:flat</code> is passed as an argument, the Array returned will contain a flattened version of the hierarchy
		#Any other argument, such as <code>:tree</code>, and the Array returned will contain an <i>un-flattened</i> Context hierarchy
		def contexts(mode=nil)
			mode ||= :flat

			if mode == :flat
				queue, ctxs = @contexts.clone, []
				while (ctx = queue.shift)
					#	myself
					ctxs << ctx
					#	all my children
					queue += ctx.contexts
				end

				ctxs
			else
				#	only the ones for our immediate children
				@contexts
			end
		end

		#Adds a sub-context to the Context hierarchy
		def add_context(context)
			@contexts << context
		end



		def freeze #:nodoc:
			super

			#	just like clone, we have to do this deeply!
			[
				@sequencer,
				@spoken, @silent, @spoken_ids,
				@instructions, @contexts,
				@state, @data,
			].each {|o| o.freeze }
		end



		class << self
			def validate(block) #:nodoc:
				raise Error, 'block required' unless block
				raise Error, 'block arity should be 0 or 1 (Context)' unless (block.arity < 2)
			end

			def invoke(block, context) #:nodoc:
				(block.arity == 0 ? block.call : block.call(context))
			end
		end
	end

	#An immutable empty Context singleton.
	#Beats returning a null
	Context::EMPTY = Context.new
	Context::EMPTY.freeze
end
