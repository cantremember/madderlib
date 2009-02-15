require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Sequencer do

	it "supports setup and teardown blocks" do
		holder = [:setup]

		sequencer = (madderlib do
			#	takes context, uses data, get and set local scope
			#	multiple are handled sequentially
			setup {|context| context.data[:word] = holder.pop }
			setup {|context| holder << :setup }

			#	takes context
			say {|context| context.data[:word] }

			#	doesn't need context, set local scope
			#	multiple are handled sequentially
			teardown { holder << :teardown }
			teardown { holder << :twice }
		end).to_sequencer

		sequencer.words.should eql(%w{ setup })
		holder.should have(3).item
		holder.should eql([:setup, :teardown, :twice])
	end



	it "handles a single say" do
		sequencer = (madderlib :single_say do
			say :hello
		end).to_sequencer

		sequencer.words.should eql(%w{ hello })
	end

	it "handles multiple says" do
		sequencer = (madderlib :multiple_say do
			#	all in sequence
			#		multiple words per phrase
			#		a few syntactical varieties
			say :cover, :contents
			and_then.say :beginning
			says :middle
			also.says :end
		end).to_sequencer

		sequencer.words.should eql(%w{
			cover contents beginning middle end
		})
	end



	it "handles flat before sequencing" do
		#	one instance, single word
		sequencer = (madderlib :flat_single_before do
			a(:ref).says :ref
			before(:ref).say :before
		end).to_sequencer

		sequencer.words.should eql(%w{ before ref })

		#	multiple instances, multiple words
		sequencer = (madderlib :flat_multiple_before do
			before(:ref).say :b, :c
			a(:ref).says(:ref)
			before(:ref).say :a
		end).to_sequencer

		sequencer.words.should eql(%w{ a b c ref })
	end

	it "handles flat after sequencing" do
		#	one instance, single word
		sequencer = (madderlib :flat_single_after do
			a(:ref).says :ref
			after(:ref).say :after
		end).to_sequencer

		sequencer.words.should eql(%w{ ref after })

		#	multiple instances, multiple words
		sequencer = (madderlib :flat_multiple_after do
			after(:ref).say :x, :y
			a(:ref).says(:ref)
			after(:ref).say :z
		end).to_sequencer

		sequencer.words.should eql(%w{ ref x y z })
	end



	it "handles nested before sequencing" do
		#	one instance, single word
		sequencer = (madderlib :nested_single_before do
			a(:ref).says :ref
			before(:ref, :inner).say :inner
			before(:inner).say :outer
		end).to_sequencer

		sequencer.words.should eql(%w{ outer inner ref })

		#	multiple instances, multiple words
		sequencer = (madderlib :nested_multiple_before do
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

		sequencer.words.should eql(%w{ a b1 b2 c d e1 e2 f ref })
	end

	it "handles nested after sequencing" do
		#	one instance, single word
		sequencer = (madderlib :nested_single_before do
			a(:ref).says :ref
			after(:inner).say :outer
			after(:ref, :inner).say :inner
		end).to_sequencer

		sequencer.words.should eql(%w{ ref inner outer })

		#	multiple instances, multiple words
		sequencer = (madderlib :nested_multiple_before do
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

		sequencer.words.should eql(%w{ ref u v1 v2 w x y1 y2 z })
	end



	it "handles complex nested sequencing" do
		sequencer = (madderlib :nested_complex do
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

		sequencer.words.should eql(%w{
			a b c d e f g h i
			ref
			r s t u v w x y z
		})
	end



	it "handles anytimes, without anything else" do
		sequencer = (madderlib :empty_anytimes do
			anytime.say :anything
		end).to_sequencer

		sequencer.words.should eql(%w{ anything })
	end

	it "handles simple anytimes" do
		#	will always occur at the end (no other option)
		sequencer = (madderlib :single_anytimes do
			say :something
			anytime.say :anything
		end).to_sequencer

		sequencer.words.should eql(%w{ something anything })

		#	only one place to go
		#		because it won't start or end the sequence
		builder = madderlib :multiple_anytimes do
			say :one
			say :two
			anytime.say :gotcha
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one gotcha two })
		end
	end

	it "handles after-positional anytimes" do
		#	nowhere to go
		#		but will NOT end the sequence
		builder = madderlib :blocked_after_anytimes do
			say :one
			a(:lower).says :two
			anytime.after(:lower).say :gotcha
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one two })
		end

		#	only one place
		builder = madderlib :simple_after_anytimes do
			say :one
			a(:lower).says :two
			say :three
			anytime.after(:lower).say :gotcha
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one two gotcha three })
		end
	end

	it "handles before-positional anytimes" do
		#	nowhere to go
		#		because it will NOT start the sequence
		builder = madderlib :blocked_before_anytimes do
			an(:upper).says :one
			say :two
			anytime.before(:upper).say :gotcha
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one two })
		end

		#	only one place
		builder = madderlib :simple_before_anytimes do
			say :one
			an(:upper).says :two
			say :three
			anytime.before(:upper).say :gotcha
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one gotcha two three })
		end
	end

	it "doesn't tolerate invalid bounding conditions" do
		(lambda do
			(builder = madderlib :between_exception_anytimes do
				#	before > after ... never works
				#		assume that before and after aren't first or last, respectively
				#		those are tolerated no-op conditions
				say :one
				a(:first).says :two
				a(:second).says :three
				say :four
				anytime.between(:second, :first).say :never
			end).to_sequencer.words
		end).should raise_error MadderLib::Error
	end

	it "handles bounded anytimes" do
		#	nowhere to go
		#		this IS a valid (though stupid) bounding condition
		builder = madderlib :bounded_nowhere_anytimes do
			a(:phrase).says :one
			anytime.after(:phrase).before(:phrase).say :never
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one })
		end

		#	one place only
		builder = madderlib :bounded_anytimes do
			say :one
			a(:lower).says :two
			an(:upper).says :three
			say :four
			anytime.between(:lower, :upper).say :gotcha
		end

		pound_on do
			items = builder.words
			items.should eql(%w{ one two gotcha three four })
		end

		#	a small range
		builder = madderlib :between_anytimes do
			a(:lower).says :one
			say :two
			an(:upper).says :three
			anytime.after(:lower).before(:upper).say :gotcha
		end

		pound_on do
			items = builder.words

			items.shift.should eql('one')
			items.pop.should eql('three')

			items.index('gotcha').should_not be_nil
			items.delete 'gotcha'
			items.should eql(%w{ two })
		end
	end
end
