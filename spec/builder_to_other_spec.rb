require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::Builder, "has component parts" do
	WORDS = %w{ one two three }



	it "is iterable" do
		words = []

		(madderlib do
			WORDS.each {|word| say word }
		end).each do |word|
			words << word
		end

		words.should eql(WORDS)
	end

	it "converts to an Array" do
		array = (madderlib do
			WORDS.each {|word| say word }
		end).to_a

		array.should eql(WORDS)
	end

	it "converts to a String" do
		s = (madderlib do
			WORDS.each {|word| say word }
		end).to_s

		#	default separator
		s.should eql(WORDS.join(' '))
	end

	it "converts to a String, with separator" do
		s = (madderlib do
			WORDS.each {|word| say word }
		end).to_s("\t")

		#	explicit separator
		s.should eql(WORDS.join("\t"))
	end
end
