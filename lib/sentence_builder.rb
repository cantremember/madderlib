#Requires all the individual components, in the proper sequence.
#That makes the use of this gem as easy as:
#
#   require 'sentence_builder'
#--

#	external
%w{ }.each {|lib| require lib }

#	internal, and in the proper sequence
%w{
	sentence_builder/core
	sentence_builder/conditional/helper
	sentence_builder/conditional/registry
	sentence_builder/conditional/allowed
	sentence_builder/conditional/repeat
	sentence_builder/extensions
	sentence_builder/phrase
	sentence_builder/sequencer
	sentence_builder/builder
}.each do |file|
	require File.expand_path(File.join(File.dirname(__FILE__), file))
end
