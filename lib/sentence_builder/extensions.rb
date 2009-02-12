class Range
	def rand(precision=0)
		span = [self.min, self.max]
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
