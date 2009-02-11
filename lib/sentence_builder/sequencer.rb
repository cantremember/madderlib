module SentenceBuilder
	class Sequencer
		include Enumerable

		attr_reader :steps

		def initialize(steps, attrs={})
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
		
		def sequence
			return @sequence if @sequence
			
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
				result_nodes += traverse(phrase, context)
			end
			
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
			
			#	finally, composite
			@sequence = []
			node = result_nodes.first
			while (node)
				@sequence << node
				node = node.after
			end

			#	finally!			
			@sequence
		end

		
		
		#	- - - - -
		private
		
		RESULT_NODE = Struct.new(:phrase, :words, :before, :after )
		
		def traverse(phrase, context)
			evaluate = lambda do |phrz|
				words = phrz.speak
				words = [words] unless Array === words
				
				#	remember how it was used
				(words.empty? ? context.silent : context.spoken) << phrz
				words
			end 
			
			results_nodes = []

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
				id = node.phrase.id
				
				more = self.before(id)
				if (more)
					node.before = RESULT_NODE.new(more, nil, nil, nil)
					queue << node.before
				end
				
				more = self.after(id)
				if (more)
					node.after = RESULT_NODE.new(more, nil, nil, nil)
					queue << node.after
				end
			end
			
			#	traverse / flatten the tree
			#	while pull
			#		if children, re-push [before node after], null its children
			#		if no children, append
			#	*YES* this is destructive
			
			stack = [tree]
			while (node = stack.pop)
				if (node.before || node.after)
					#	re-traverse us all
					stack << node.before if node.before
					stack << node
					stack << node.after if node.after
					
					#	pretend i didn't have any children
					node.before = node.after = nil
				else
					results_nodes << node
				end
			end
				
			#	now, re-join them
			#	the Array and the nodes are in sequence
			#	allows insertions without re-indexing
			prev = nil
			result_nodes.each do |node|
				if prev
					prev.after = node
					node.before = prev
				end
				prev = node
			end 
			
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
			@spokey, @silent = [], []
			@state = {}
		end
	end
end
