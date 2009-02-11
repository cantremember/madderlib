require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "to Sequencer" do

	it "handles a single say" do
		sequencer = (sentence_builder :single_say do
			say :hello
		end).to_sequencer
		
		sequencer.items.should eql([:hello])
	end

	it "handles multiple says" do
		sequencer = (sentence_builder :multiple_say do
			#	all in sequence
			#		multiple words per phrase
			#		a few syntactical varieties
			say :cover, :contents
			and_then.say :beginning
			says :middle
			also.says :end
		end).to_sequencer
		
		sequencer.items.should eql([
			:cover, :contents, :beginning, :middle, :end
		])
	end
	
	
	
	it "handles flat before sequencing" do
		#	one instance, single word
		sequencer = (sentence_builder :flat_single_before do
			a(:ref).says :ref
			before(:ref).say :before
		end).to_sequencer
		
		sequencer.items.should eql([:before, :ref])
		
		#	multiple instances, multiple words
		sequencer = (sentence_builder :flat_multiple_before do
			before(:ref).say :b, :c
			a(:ref).says(:ref)
			before(:ref).say :a
		end).to_sequencer
		
		sequencer.items.should eql([:a, :b, :c, :ref])
	end

	it "handles flat after sequencing" do
		#	one instance, single word
		sequencer = (sentence_builder :flat_single_after do
			a(:ref).says :ref
			after(:ref).say :after
		end).to_sequencer
		
		sequencer.items.should eql([:ref, :after])
		
		#	multiple instances, multiple words
		sequencer = (sentence_builder :flat_multiple_after do
			after(:ref).say :x, :y
			a(:ref).says(:ref)
			after(:ref).say :z
		end).to_sequencer
		
		sequencer.items.should eql([:ref, :x, :y, :z])
	end

	
	
	it "handles nested before sequencing" do
		#	one instance, single word
		sequencer = (sentence_builder :nested_single_before do
			a(:ref).says :ref
			before(:ref, :inner).say :inner
			before(:inner).say :outer
		end).to_sequencer
		
		sequencer.items.should eql([:outer, :inner, :ref])
		
		#	multiple instances, multiple words
		sequencer = (sentence_builder :nested_multiple_before do
			# visually:
			#	[ :a [ :b [:c :d ] :e ] :f :ref ]
			before(:ref).say :f
			before(:ref, :inner_e).say :e1, :e2
			before(:inner_e, :outer_d).say :d
			a(:ref).says(:ref)
			before(:outer_d).say :c
			before(:inner_e).say :b1, :b2
			before(:ref).say :a
		end).to_sequencer
		
		sequencer.items.should eql([:a, :b1, :b2, :c, :d, :e1, :e2, :f, :ref])
	end
	
	
	it "handles nested after sequencing" do
		#	one instance, single word
		sequencer = (sentence_builder :nested_single_before do
			a(:ref).says :ref
			after(:inner).say :outer
			after(:ref, :inner).say :inner
		end).to_sequencer
		
		sequencer.items.should eql([:ref, :inner, :outer])
		
		#	multiple instances, multiple words
		sequencer = (sentence_builder :nested_multiple_before do
			# visually:
			#	[ :ref :u [ :v [ :w :x ] :y ] :z ]
			after(:ref).say :u
			after(:ref, :inner_v).say :v1, :v2
			after(:inner_v, :outer_w).say :w
			a(:ref).says(:ref)
			after(:outer_w).say :x
			after(:inner_v).say :y1, :y2
			after(:ref).say :z
		end).to_sequencer
		
		sequencer.items.should eql([:ref, :u, :v1, :v2, :w, :x, :y1, :y2, :z])
	end

	
		
	it "handles complex nested sequencing" do
		sequencer = (sentence_builder :nested_complex do
			# visually:
			#	[ :a [ [ :b :c [ :d :e ] ] :f [ :g :h ] :i ] :ref [ :r [ :s :t ] :u [ [ :v :w ] :x :y ] ] :z ]
			#		as if that helps
			#		yes, it's palindromic around :ref
			before(:c).say :b
			before(:f, :c).say :c
			after(:c, :d).say :d
			after(:d).say :e
			before(:ref, :f).say :f
			before(:h).say :g
			after(:f, :h).say :h
			#	dupl after
			after(:f).say :i
			#	dupl before
			before(:ref).say :a

			a(:ref).says(:ref)
			
			after(:x).say :y
			after(:u, :x).say :x
			before(:x, :w).say :w
			before(:w).say :v
			after(:ref, :u).say :u
			before(:u, :t).say :t
			before(:t).say :s
			#	dupl before
			before(:u).say :r
			#	dupl after
			after(:ref).say :z
		end).to_sequencer
		
		sequencer.items.should eql([
			:a, :b, :c, :d, :e, :f, :g, :h, :i, 
			:ref,
			:r, :s, :t, :u, :v, :w, :x, :y, :z,
		])
	end

end
