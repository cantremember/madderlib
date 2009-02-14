#Requires all the individual components, in the proper sequence.
#That makes the use of this gem as easy as:
#
#   require 'madderlib'
#--

#	external
%w{ }.each {|lib| require lib }

#	internal, and in the proper sequence
%w{
	madderlib/core
	madderlib/context
	madderlib/conditional/helper
	madderlib/conditional/registry
	madderlib/conditional/allowed
	madderlib/conditional/repeat
	madderlib/conditional/recur
	madderlib/conditional/likely
	madderlib/extensions
	madderlib/instruction
	madderlib/phrase
	madderlib/sequencer
	madderlib/builder
}.each do |file|
	require File.expand_path(File.join(File.dirname(__FILE__), file))
end
