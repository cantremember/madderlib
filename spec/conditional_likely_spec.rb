require File.join(File.dirname(__FILE__), 'spec_helper')



describe SentenceBuilder::Conditional::Likely do
	def distribution(words, map=nil)
		map ||= {}
		words.each do |word|
			map[word] = (map[word] || 0) + 1
		end

		return map
	end



	it "by default has a 50/50 split" do
		builder = sentence_builder do
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

		diff = map['fish'] - map['buffalo']
		diff.should be_close(0, 20)
	end

	it "supports nothing" do
		builder = sentence_builder do
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

		diff = 100 - map['something nice']
		diff.should be_close(50, 20)
	end



	it "getting a 2/1 split" do
		#	testing out various alias formats, etc
		builder = sentence_builder :split_2_1 do
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

		diff = map['fish'].to_f / map['buffalo']
		diff.should be_close(2.0, 0.6)
	end

	it "getting a 3/1 split" do
		#	testing out various alias formats, etcnext
		builder = sentence_builder :split_3_1 do
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
		diff = map['fish'].to_f / map['buffalo']
		diff.should be_close(3.0, 1.0)
	end



	it "getting a 3/2/1 split" do
		#	testing out transferrence from 'or' operation to likelihood
		builder = sentence_builder :split_3_2_1 do
			say 'faith'
			alternately(2).says('hope')
			#	range is supported, but not recommended
			it.or(0..3).says('charity')
		end

		refs = %w{ faith hope charity }
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

		diff = map['charity'].to_f / map['faith']
		#	i've seen it range from 2 to 5 ... absurd!
		diff.should be_close(3.5, 2.0)

		diff = map['hope'].to_f / map['faith']
		diff.should be_close(2.0, 0.8)
	end

end
