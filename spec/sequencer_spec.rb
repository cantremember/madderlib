require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Builder, "to Sequencer" do
	def pound_on
		#	that'll be enough
		100.times { yield }
	end



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



	it "handles anytimes, without anything else" do
		sequencer = (sentence_builder :empty_anytimes do
			anytime.say :anything
		end).to_sequencer

		sequencer.items.should eql([:anything])
	end

	it "handles simple anytimes" do
		#	will always occur at the end (no other option)
		sequencer = (sentence_builder :single_anytimes do
			say :something
			anytime.say :anything
		end).to_sequencer

		sequencer.items.should eql([:something, :anything])

		#	only one place to go
		#		because it won't start or end the sequence
		builder = sentence_builder :multiple_anytimes do
			say :one
			say :two
			anytime.say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one, :gotcha, :two])
		end
	end

	it "handles after-positional anytimes" do
		#	nowhere to go
		#		but will NOT end the sequence
		builder = sentence_builder :blocked_after_anytimes do
			say :one
			a(:lower).says :two
			anytime.after(:lower).say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one, :two])
		end

		#	only one place
		builder = sentence_builder :simple_after_anytimes do
			say :one
			a(:lower).says :two
			say :three
			anytime.after(:lower).say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one, :two, :gotcha, :three])
		end
	end

	it "handles before-positional anytimes" do
		#	nowhere to go
		#		because it will NOT start the sequence
		builder = sentence_builder :blocked_before_anytimes do
			an(:upper).says :one
			say :two
			anytime.before(:upper).say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one, :two])
		end

		#	only one place
		builder = sentence_builder :simple_before_anytimes do
			say :one
			an(:upper).says :two
			say :three
			anytime.before(:upper).say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one, :gotcha, :two, :three])
		end
	end

	it "doesn't tolerate invalid bounding conditions" do
		(lambda do
			(builder = sentence_builder :between_exception_anytimes do
				#	before > after ... never works
				#		assume that before and after aren't first or last, respectively
				#		those are tolerated no-op conditions
				say :one
				a(:first).says :two
				a(:second).says :three
				say :four
				anytime.between(:second, :first).say :never
			end).to_sequencer.items
		end).should raise_error SentenceBuilder::Error
	end

	it "handles bounded anytimes" do
		#	nowhere to go
		#		this IS a valid (though stupid) bounding condition
		builder = sentence_builder :bounded_nowhere_anytimes do
			a(:phrase).says :one
			anytime.after(:phrase).before(:phrase).say :never
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one])
		end

		#	one place only
		builder = sentence_builder :bounded_anytimes do
			say :one
			a(:lower).says :two
			an(:upper).says :three
			say :four
			anytime.between(:lower, :upper).say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items
			items.should eql([:one, :two, :gotcha, :three, :four])
		end

		#	a small range
		builder = sentence_builder :between_anytimes do
			a(:lower).says :one
			say :two
			an(:upper).says :three
			anytime.after(:lower).before(:upper).say :gotcha
		end

		pound_on do
			#	a sequencer caches its items
			items = builder.to_sequencer.items

			items.shift.should equal(:one)
			items.pop.should equal(:three)

			items.index(:gotcha).should_not be_nil
			items.delete :gotcha
			items.should eql([:two])
		end
	end
end
