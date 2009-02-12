require File.join(File.dirname(__FILE__), 'spec_helper')



describe Range do
	it "still doesn't handle floats" do
		range = Range.new(0, 1.9)
		range.max.should eql(1)
	end

	it "still doesn't inverted orders" do
		range = Range.new(6, 4)
		range.min.should be_nil
		range.max.should be_nil
	end

	it "provides a random value, with optional precision" do
		#	trial by fire
		[Range.new(1, 3), Range.new(-1, 5)].each do |range|
			span = [range.min, range.max]
			Range.new(0, 4).each do |precision|
				100.times do
					value = range.rand(precision)
					value.integer?.should be_true if (precision == 0)
					value.should satisfy {|v| (v >= span.min) && (v < span.max) }
				end
			end
		end
	end
end
