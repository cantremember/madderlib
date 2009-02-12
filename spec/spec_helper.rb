#	our dependencies
require File.join(File.dirname(__FILE__), '..', 'lib', 'sentence_builder')

#	external
%w{ rubygems spec }.each {|lib| require lib }

#	optional
require 'ruby-debug' rescue nil



module SentenceBuilder
	class Builder
		#	normally private
		#	oops! reserved names!
		###attr_reader :ordered, :depends
		def orderings; @ordered; end
		def dependencies; @depends; end

		send :public, :to_sequencer
	end

	class Sequencer
		#	normally private
		attr_reader :steps

		#	oops! reserved names!
		###attr_reader :anytime, :before, :after
		def anytimes; @anytime; end
		def befores; @before; end
		def afters; @after; end

		send :public, :sequence
		send :public, :traverse
	end

	class Phrase
		class << self
			send :public, :wordify
		end
	end

	class AnytimePhrase
		attr_reader :repeat_logic
	end
end
