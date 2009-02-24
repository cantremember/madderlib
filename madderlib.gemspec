Gem::Specification.new do |s|
	s.specification_version = 2 if s.respond_to? :specification_version=
	s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
	s.required_ruby_version = '>= 1.8'

	s.name = 'madderlib'
	s.version = '0.1.0'
	s.date = "2009-02-14"

	s.description = "MadderLib : a Sentence-Building DSL for the easily amused"
	s.summary     = "#{s.name} #{s.version}"

	s.homepage = "http://wiki.cantremember.com/MadderLib"
	s.authors = ["Dan Foley"]
	s.email = 'admin@cantremember.com'  # = MANIFEST =
  s.files = %w[
    CHANGELOG
    LICENSE
    README.rdoc
    Rakefile
    lib/madderlib.rb
    lib/madderlib/builder.rb
    lib/madderlib/conditional/allowed.rb
    lib/madderlib/conditional/helper.rb
    lib/madderlib/conditional/likely.rb
    lib/madderlib/conditional/recur.rb
    lib/madderlib/conditional/registry.rb
    lib/madderlib/conditional/repeat.rb
    lib/madderlib/context.rb
    lib/madderlib/core.rb
    lib/madderlib/extensions.rb
    lib/madderlib/instruction.rb
    lib/madderlib/phrase.rb
    lib/madderlib/sequencer.rb
    madderlib.gemspec
    spec/benchmark_spec.rb
    spec/builder_spec.rb
    spec/builder_to_other_spec.rb
    spec/builder_to_sequencer_spec.rb
    spec/conditional_allowed_spec.rb
    spec/conditional_helper_spec.rb
    spec/conditional_likely_spec.rb
    spec/conditional_recur_spec.rb
    spec/conditional_registry_spec.rb
    spec/conditional_repeat_spec.rb
    spec/doc_spec.rb
    spec/error_spec.rb
    spec/examples_spec.rb
    spec/extensions_spec.rb
    spec/grammar_spec.rb
    spec/instruction_spec.rb
    spec/kernel_spec.rb
    spec/phrase_spec.rb
    spec/sequencer_spec.rb
    spec/spec_helper.rb
  ]
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
