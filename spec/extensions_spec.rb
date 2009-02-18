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
			#	high precision, to increase remainder likelihood
			[0, 5].each do |precision|
				pound_on do
					#	exclusive
					value = range.rand(precision)
					(value.to_f == value.to_i.to_f).should equal(precision == 0)
					value.should satisfy {|v| (v >= span.min) && (v < span.max) }

					#	inclusive
					value = range.rand_inclusive(precision)
					(value.to_f == value.to_i.to_f).should equal(precision == 0)
					value.should satisfy {|v| (v >= span.min) && (v < (span.max + 1)) }
				end
			end
		end
	end
end

describe Array do
	it "has to_byte_s, which requires all integers" do
		(lambda { [32, 32, '32'].to_byte_s }).should raise_error
	end

	it "has to_byte_s" do
		[32, 32, 32].to_byte_s.should eql(' ' * 3)
	end
end
