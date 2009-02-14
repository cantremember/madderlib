require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Conditional::Likely do
	def distribution(words, map=nil)
		map ||= {}
		words.each do |word|
			map[word] = (map[word] || 0) + 1
		end

		return map
	end



	it "by default has a 50/50 split" do
		builder = madderlib do
			say 'buffalo'
			it.alternately.says 'fish'
		end

		refs = %w{ buffalo fish }
		map = nil
		pound_on do
			map = distribution(builder.words, map)
		end

		#	now that'we re done
		#		should have hit each once
		#		and should have a reasonable distribution (though who can tell)
		map.should have(refs.size).items
		map.keys.each {|key| refs.include?(key).should be_true }

		map['buffalo'].should be_close(50, 20)
		map['fish'].should be_close(50, 20)
	end

	it "supports nothing" do
		builder = madderlib do
			say 'something nice'
			alternately.nothing
		end

		map = nil
		pound_on(100) do
			map = distribution(builder.words, map)
		end

		#	now that'we re done
		#		should have hit each once
		#		and should have a reasonable distribution (though who can tell)
		map.should have(1).items
		map['something nice'].should_not be_nil

		map['something nice'].should be_close(50, 20)
	end



	it "getting a 2/1 split" do
		#	testing out various alias formats, etc
		builder = madderlib :split_2_1 do
			say 'buffalo'
			it.alternately.says('fish').likely(2)
		end

		refs = %w{ buffalo fish }
		map = nil
		pound_on do
			words = builder.words
			map = distribution(words, map)
		end

		#	now that'we re done
		#		should have hit each once
		#		and should have a reasonable distribution (though who can tell)
		map.should have(refs.size).items
		map.keys.each {|key| refs.include?(key).should be_true }

		map['buffalo'].should be_close(33, 20)
		map['fish'].should be_close(66, 20)
	end

	it "getting a 3/1 split" do
		#	testing out various alias formats, etcnext
		builder = madderlib :split_3_1 do
			say 'buffalo'
			it.alternately.says('fish').weighing { 2 + 1 }
		end

		refs = %w{ buffalo fish }
		map = nil
		pound_on do
			words = builder.words
			map = distribution(words, map)
		end

		#	now that'we re done
		#		should have hit each once
		#		and should have a reasonable distribution (though who can tell)
		map.should have(refs.size).items
		map.keys.each {|key| refs.include?(key).should be_true }

		map['buffalo'].should be_close(25, 20)
		map['fish'].should be_close(75, 20)
	end



	it "getting a 3/2/1 split" do
		#	testing out transferrence from 'or' operation to likelihood
		builder = madderlib :split_3_2_1 do
			say 'faith'
			alternately(2).says('hope')
			#	range is supported, but not recommended
			it.or(0..3).says('charity')
		end

		refs = %w{ faith hope charity }
		map = nil
		pound_on 150 do
			words = builder.words
			map = distribution(words, map)
		end

		#	now that'we re done
		#		should have hit each once
		#		and should have a reasonable distribution (though who can tell)
		map.should have(refs.size).items
		map.keys.each {|key| refs.include?(key).should be_true }

		map['faith'].should be_close(25, 20)
		map['hope'].should be_close(50, 20)
		map['charity'].should be_close(75, 20)
	end

end
