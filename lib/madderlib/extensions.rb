class Range
	#Returns a random number between the min and max of the Range.
	#An optional precision can be provided, which assumed to be 0 (eg. Fixnum.floor)
	def rand(precision=0)
		rand_from self.min, self.max, precision
	end

	#Returns a random number within the min and max of the Range, which can potentially include the max.
	#An optional precision can be provided, which assumed to be 0 (eg. Fixnum.floor)
	def rand_inclusive(precision=0)
		rand_from self.min, self.max + 1, precision
	end

	#	- - - - -
	private

	def rand_from(a, b, precision)
		span = [a, b]
		min, max = span.min, span.max

		min + if precision == 0
			#	no effort required
			Kernel.rand(max - min).floor
		else
			#	some precision
			p = (10 ** precision).to_f
			Kernel.rand((max - min) * p) / p
		end
	end
end



class Array
	#Composites the Array -- of Fixnums (characters) -- into a String.
	#An exception will be raised if any value in the Array is not a Fixnum
	def to_byte_s
		self.collect {|c| c.chr }.join(nil)
	end
end
