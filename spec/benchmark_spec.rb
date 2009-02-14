require File.join(File.dirname(__FILE__), 'spec_helper')

require 'benchmark'
include Benchmark



=begin
class Bencher
	attr_accessor :debug

	def call(name='(none)', &block)
		x = nil
		unless @debug
			x = block.call
		else
			bm(6) do |reporter|
				reporter.report(name) { x = block.call }
			end
		end
		x
	end
end

BENCHER = Bencher.new
=end



describe SentenceBuilder, "benchmarking" do

	it "conditional logic" do
		builder = sentence_builder :split_3_2_1 do
			say('flopsy').or(2).say('mopsy').or(3).say('cottontail')
			say('ate')
			say('many').times(2, 4)
			%w{ cherries churches rocks ducks }.each do |wrong|
				say(wrong).if { false }
			end
			say('carrots')
		end

=begin
		bm(6) do |reporter|
			reporter.report(time.to_s) do
			end
		end
=end

		delta = nil
		(1..10).each do |time|
			#	fake progress
			print '^'

			t = Time.now.to_f

			pound_on do
				words = builder.words
			end

			#	the operations should take a very similar amount of time
			#		no degradation, like we saw with Generator
			#		still, we need to be generous (1/2 sec)
			t = (Time.now.to_f - t)
			t.should be_close(delta, 0.5) if delta
			delta = t
		end	end

end
