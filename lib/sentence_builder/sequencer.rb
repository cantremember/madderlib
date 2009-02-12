module SentenceBuilder
	class Sequencer
		include Enumerable

		attr_reader :builder, :steps, :ids

		def initialize(builder, steps, ids, attrs={})
			@builder, @steps, @ids = builder, steps, ids

			#	arbitrary attributes for convenience
			(attrs || {}).each do |k, v|
				self.instance_variable_set "@#{k}".to_sym, v
			end

			#	prime
			@anytime ||= []
			@before ||= {}
			@after ||= {}
		end

		def before(ref)
			@before[ref]
		end

		def after(ref)
			@after[ref]
		end



		#	returns each word in the sequence
		def words
			#	yes, we do cache at this level
			#	it's publicly exposed
			unless @items
				#	composite the words
				#		each node contains an array of words
				@items = self.sequence.collect {|node| node.words }
				@items = @items.flatten
			end

			@items
		end
		alias :items :words

		#	iterates over each word in the sequence
		def each_word
			self.words.each {|word| yield word }
		end
		alias :each :each_word

		#	returns each phrase in the sequence
		def each_phrase
			self.sequence.each {|node| yield node.phrase }
		end



		#	- - - - -
		private

		RESULT_NODE = Struct.new(:phrase, :words, :before, :after )

		def sequence
			#	this is where we do all the sequencing
			#	each phrase gets invoked, and any words it returns are used
			#	if no words are returned, it's skipped
			#	otherwise, look for befores and afters, and apply them
			#		same logic for each before / after as above
			#	then, pepper in the anytimes, including boundaries, etc
			context = Context.new(self)

			if (@setup)
				#	dispatch to the setup block
				Context.invoke(@setup, context)
			end

			#	all the basic steps
			#		one node per phrase
			#		in the proper order
			#	we can flatten it immediately
			result_nodes = []
			steps.each do |phrase|
				result_nodes += traverse(phrase, context)
			end

			#	link them all together
			#		the Array and the nodes are in sequence
			#		this allows for anytime insertions without re-indexing
			prev = nil
			result_nodes.each do |node|
				if prev
					prev.after = node
					node.before = prev
				end
				prev = node
			end

			#	now pepper in the anytimes
			result_size = result_nodes.size

			#	this will always find the first match
			#	TODO:  optionally we could create two loops for before and after
			index_of = lambda do |id|
				found = nil
				Range.new(0, result_size - 1).each do |idx|
					if result_nodes[idx].phrase.id == id
						#	grr.  can't return.
						found = idx
						break
					end
				end
				found
			end

			anytimes.each do |anytime|
				#	we don't want an anytime to end the sentence
				#		consistent with not letting one start, which is implicit here
				#		UNLESS it's an empty set of nodes
				before_index = false

				to = result_size - 1
				if anytime.before
					#	expose this for subsequent checks
					before_index = index_of.call(anytime.before)

					#	you can't intentionally inject before the first item
					#		it's not an error, it's just there's no room for anytime
					if before_index
						next if (before_index == 0)
						to = before_index
					end
				end

				#	can't start the sentence either
				#		eg. can't insert before 0
				from = 0
				if anytime.after
					index = index_of.call(anytime.after)

					#	you can't intentionally inject after the last item
					#		it's not an error, it's just there's no room for anytime
					if index
						next if (index == (result_size - 1))
						from = index
					end

					if to < from
						#	you can't explicitly bound like that
						raise Error, "bounding failure between #{anytime.after.inspect} and #{anytime.before.inspect}" if (index && before_index)

						#	partially bounded conditions, that's different ...
						#	handle special case: there's only one place to put the thing
						from = to
					end
				end

				loop do
					these_nodes = traverse(anytime, context)
					#	this would happen if:
					#		the anytime is exhauseted
					#		it conditionally returned nothing
					#		both of those are treated as exit conditions
					#		if you don'w want conditional nothings, don't permit them
					break if these_nodes.empty?

					#	TODO:
					#	add logic so that multiple anytimes won't be adjacent
					#		requires an exhausting index pool
					#		probably okay to stop once the pool is exhausted, even if there's more anytime
					#	if will get appended after the chosen position
					#		don't want to append to end of sequence, so (to -= 1)
					#		so offset
					#	it is possible to have only one place to put the thing
					to -= 1
					to = 0 if to < 0

					where = ((from >= to) ? from : Range.new(from, to).rand)
					node = result_nodes[where]

					unless node
						#	special case:  append to end
						#		see considerations above
						raise Error, "no node found at #{where}" unless where == result_size
						if where == 0
							#	you're all there is
							result_nodes += these_nodes
						else
							#	append to end
							node = result_nodes.last
						end
					end

					if node
						#	splice
						head = these_nodes.first
						tail = these_nodes.last

						tail.after = node.after
						tail.after.before = tail if tail.after
						node.after = head
						head.before = node
					end
				end
			end

			#	finally, flatten the node tree
			flattened = []
			node = result_nodes.first
			while (node)
				flattened << node
				node = node.after
			end

			if (@teardown)
				#	dispatch to the setup block
				Context.invoke(@teardown, context)
			end

			flattened
		end

		def traverse(phrase, context)
			evaluate = lambda do |phrz|
				words = phrz.speak(context)
				words = [words] unless Array === words

				#	remember how it was used
				if words.empty?
					context.silent << phrz
				else
					context.spoken << phrz
					context.spoken_ids << phrz.id if phrz.id
				end

				words
			end

			result_nodes = []

			#	build the phrase hierarchy
			#		before / after tree, with non-recursive queue
			#		chose a queue to imply some order
			tree = RESULT_NODE.new(phrase, nil, nil, nil)
			queue = [tree]

			while (node = queue.shift)
				#	evaluate the phrase
				node.words = evaluate.call(node.phrase)
				next if node.words.empty?

				#	check the wrappers
				#		each is an array of phrases
				id = node.phrase.id

				#	as built, for understandability, the first before is sequentially first
				#		we're appending in reference to an un-moving node
				#		and it actually works the same way...
				#		the farther away the node, the earlier it will be traversed
				(self.before(id) || []).each do |more|
					node.before = RESULT_NODE.new(more, nil, node.before, nil)
					queue << node.before
				end

				#	the last after is sequentially last
				#		the node doesn't move, and the last after needs to be at the end of the chain
				#		so, reverse order is appropriate
				#	heh.  this is not meant to be performant, it's meant to be comprehensible
				#		at least at the individual captured data structure level
				(self.after(id) || []).reverse.each do |more|
					node.after = RESULT_NODE.new(more, nil, nil, node.after)
					queue << node.after
				end
			end

			#	traverse / flatten the tree
			#	while pull
			#		if children, re-push [after node before], null its children
			#		if no children, append
			#		result nodes are appended via stack ordering, so it's 'backwards'
			#	*YES* this is destructive

			stack = [tree]

			while (node = stack.pop)
				#	we could have empty nodes
				#		they won't have children, that was taken care of
				#		but the node placeholders will still be there
				next if node.words.empty?

				if (node.before || node.after)
					#	re-traverse us all
					stack << node.after if node.after
					stack << node
					stack << node.before if node.before

					#	pretend i didn't have any children
					node.before = node.after = nil
				else
					result_nodes << node
				end
			end

			#	the nodes we return are *not* linked together
			#	just an array
			result_nodes
		end
	end



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
