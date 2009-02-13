module SentenceBuilder
	class Context
		attr_reader :sequencer
		attr_reader :spoken
		attr_reader :silent
		attr_reader :spoken_ids
		attr_reader :data

		def initialize(sequencer)
			@sequencer = sequencer
			@spoken, @silent, @spoken_ids = [], [], []
			@state, @data = {}, {}
		end

		def state(key)
			hash = @state[key]
			@state[key] = hash = {} unless hash
			hash
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
end
