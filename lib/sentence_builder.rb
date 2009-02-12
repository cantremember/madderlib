#Requires all the individual Bitly4R components, in the proper sequence.
#That makes the use of this gem as easy as:
#
#   require 'sentence_builder'
#--

#	external
%w{ }.each {|lib| require lib }

#	internal, and in the proper sequence
%w{
	sentence_builder/core
	sentence_builder/conditional/pattern
	sentence_builder/conditional/closure
	sentence_builder/extensions
	sentence_builder/builder
	sentence_builder/sequencer
	sentence_builder/phrase
}.each do |file|
	require File.expand_path(File.join(File.dirname(__FILE__), file))
end
