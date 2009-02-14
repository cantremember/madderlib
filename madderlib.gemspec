Gem::Specification.new do |s|
	s.specification_version = 2 if s.respond_to? :specification_version=
	s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
	s.required_ruby_version = '>= 1.8'

	s.name = 'madderlib'
	s.version = '0.1.0'
	s.date = "2009-02-14"

	s.description = "MadderLib : ___"
	s.summary     = "#{s.name} #{s.version}"

	s.homepage = "http://wiki.cantremember.com/MadderLib"
	s.authors = ["Dan Foley"]
	s.email = 'admin@cantremember.com'

	# = MANIFEST =
	s.files = %w{
		CHANGELOG
		LICENSE
		README.rdoc
		Rakefile
	}
	s.files += Dir.glob('lib/**/*.rb')
	s.test_files = Dir.glob('spec/**/*.rb')
	# = MANIFEST =

	s.require_paths = %w{lib}

=begin
	s.add_dependency 'GEM-NAME', '>= GEM-VERSION'
=end

	s.has_rdoc = true
	#	only because there ain't no spaces in the title ...
	s.rdoc_options = %w{ --line-numbers --inline-source --title MadderLib --main README.rdoc }
	s.extra_rdoc_files = %w{ README.rdoc CHANGELOG LICENSE }

	s.rubyforge_project = 'madderlib'
	s.rubygems_version = '1.1.1'
end
