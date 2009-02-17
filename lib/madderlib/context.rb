module MadderLib
	class Context
		attr_reader :sequencer
		attr_reader :spoken
		attr_reader :silent
		attr_reader :spoken_ids
		attr_reader :instructions
		attr_reader :data

		def initialize(sequencer)
			@sequencer = sequencer
			@spoken, @silent, @spoken_ids = [], [], []
			@instructions, @contexts = [], []
			@state, @data = {}, {}
		end

		def builder
			@sequencer.builder
		end

		def state(key)
			hash = @state[key]
			@state[key] = hash = {} unless hash
			hash
		end

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

		def add_context(context)
			@contexts << context
		end



		class << self
			def validate(block)
				raise Error, 'block required' unless block
				raise Error, 'block arity should be 0 or 1 (Context)' unless (block.arity < 2)
			end

			def invoke(block, context)
				(block.arity == 0 ? block.call : block.call(context))
			end
		end
	end

	Context::EMPTY = Context.new(nil)
end
