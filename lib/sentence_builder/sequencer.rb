module SentenceBuilder
	class Sequencer
		include Enumerable

		attr_reader :builder, :steps

		def initialize(builder, steps, attrs={})
			@builder = builder
			@steps = steps

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

		
				
		def each
			###Enumerator.new(list)
			###Enumerator.new(list, :items)
			#	gawd, that's all wrong...
			#	you have to implement the block traversal
			self.sequence.each {|word| yield word }
		end
		
		def words
			#	yes, we do cache at this level
			#	it's publicly exposed
			unless @words
				#	composite the words
				#		each node contains an array of words
				@words = self.sequence.collect {|node| node.words }
				@words = @words.flatten
			end
			
			@words
		end
		alias :items :words
		
		
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
		
			#	all the basic steps
			#		one node per phrase
			#		in the proper order
			#	we can flatten it immediately
			result_nodes = []
			steps.each do |phrase|
				traversal = traverse(phrase, context)
#debugger
				result_nodes += traversal
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
#debugger
						
			#	now pepper in the anytimes
			
			#	this will always find the first match
			#	TODO:  optionally we could create two loops for before and after
			index_of = lambda do |id|
				[0 .. result_nodes.size - 1].each do |idx|
					if result_nodes[idx].phrase.id == id
						start = idx
						break
					end
				end			
			end
			 			
			anytimes.each do |anytime|
				from = 0					
				if anytime.after
					index = index_of.call(anytime.after)
					from = index + 1 if index 
				end
				
				#	we don't want an anytime to end the sentence
				#	consistent with not letting one start, which is implicit here
				to = result_nodes.size - 1
				if anytime.before
					index = index_of.call(anytime.before)
					to = index if index
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
					#	requires an exhausting index pool
					#	probably okay to stop once the pool is exhausted, even if there's more anytime
					where = Range.new(from, to).rand
					
					#	splice					
					node = result_nodes[where]
					from = these_nodes.first
					to = these_nodes.last
		
					node.after.before = to
					node.after = from
					from.before = node
					to.after = node
				end
			end
#debugger
						
			#	finally, flatten the node tree
			flattened = []
			node = result_nodes.first
			while (node)
				flattened << node
				node = node.after
			end
					
			flattened
		end
		
		def traverse(phrase, context)
			evaluate = lambda do |phrz|
				words = phrz.speak(context)
				words = [words] unless Array === words
				
				#	remember how it was used
				(words.empty? ? context.silent : context.spoken) << phrz
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
#debugger if @builder.id == :nested_single_before
			end
#debugger if @builder.id == :nested_single_before
			
			#	the nodes we return are *not* linked together			
			#	just an array
			result_nodes
		end
	end



	class Context
		attr_reader :sequencer
		attr_reader :spoken
		attr_reader :silent
		attr_reader :state
		
		def initialize(sequencer)
			@sequencer = sequencer
			@spoken, @silent = [], []
			@state = {}
		end
	end
end
