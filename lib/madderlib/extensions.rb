class Range
	def rand(precision=0)
		rand_from self.min, self.max, precision
	end

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
