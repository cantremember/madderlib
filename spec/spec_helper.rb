#	external
%w{ rubygems spec }.each {|lib| require lib }

#	optional
require 'ruby-debug' rescue nil

#	our dependencies
#	loaded after debug is ready
require File.join(File.dirname(__FILE__), '..', 'lib', 'madderlib')



module Spec::DSL::Main
	def pound_on(count=100)
		#	that'll be enough
		count.times { yield }
	end
end



module MadderLib
	class Builder
		#	normally private
		#	oops! reserved names!
		###attr_reader :ordered, :depends
		def orderings; @ordered; end
		def dependencies; @depends; end
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

	class Instruction
		class << self
			send :public, :wordify
		end
	end

	class AnytimePhrase
		attr_reader :repeat_logic
	end
end
