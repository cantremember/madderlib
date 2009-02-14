require File.join(File.dirname(__FILE__), 'spec_helper')



describe MadderLib::KernelMethods, "simple examples" do

	it "combinatorial example" do
		#	useless, but at leasts tests composite operations
		builder = madderlib do
			say 'hello', 'and'
			say('never').if { false }.or.say('likely').likely(2).or.say('repeat').repeat(3).or(99).nothing
		end
		builder.validate	end

end
