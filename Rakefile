require 'rubygems'
require 'rake/clean'
require 'fileutils'

task :default => :test

# SPECS ===============================================================

desc 'Run specs with story style output'
task :spec do
	sh 'spec --format specdoc spec/*_spec.rb'
end

desc 'Run specs with unit test style output'
task :test => FileList['spec/*_spec.rb'] do |t|
	suite = t.prerequisites.map{|f| "-r#{f.chomp('.rb')}"}.join(' ')
	sh "ruby -Ilib:spec #{suite} -e ''", :verbose => false
end

# PACKAGING ============================================================

# Load the gemspec using the same limitations as github
def spec
	@spec ||=
		begin
			require 'rubygems/specification'
			data = File.read('sentence_builder.gemspec')
			spec = nil
			#	OS X didn't like SAFE = 2
			#		(eval):25:in `glob': Insecure operation - glob
			Thread.new { spec = eval("$SAFE = 2\n#{data}") }.join
			spec
		end
end

def package(ext='')
	"dist/sentence_builder-#{spec.version}" + ext
end

desc 'Build packages'
task :package => %w[.gem .tar.gz].map {|e| package(e)}

desc 'Build and install as local gem'
task :install => package('.gem') do
	sh "gem install #{package('.gem')}"
end

directory 'dist/'

file package('.gem') => %w[dist/ sentence_builder.gemspec] + spec.files do |f|
	sh "gem build sentence_builder.gemspec"
	mv File.basename(f.name), f.name
end

file package('.tar.gz') => %w[dist/] + spec.files do |f|
	sh "git archive --format=tar HEAD | gzip > #{f.name}"
end

# Rubyforge Release / Publish Tasks ==================================

desc 'Publish website to rubyforge'
task 'publish:doc' => 'doc/api/index.html' do
	sh 'scp -rp doc/* cantremember@rubyforge.org:/var/www/gforge-projects/sentence_builder/'
end

task 'publish:gem' => [package('.gem'), package('.tar.gz')] do |t|
	sh <<-end
		rubyforge add_release sentence_builder sentence_builder #{spec.version} #{package('.gem')} &&
		rubyforge add_file    sentence_builder sentence_builder #{spec.version} #{package('.tar.gz')}
	end
end

# Website ============================================================
# Building docs

task 'doc'     => ['doc:api','doc:site']

desc 'Generate RDoc under doc/api'
task 'doc:api' => ['doc/api/index.html']

file 'doc/api/index.html' => FileList['lib/**/*.rb','README.rdoc','CHANGELOG','LICENSE'] do |f|
	rb_files = f.prerequisites
	sh((<<-end).gsub(/\s+/, ' '))
		rdoc --line-numbers --inline-source --title SentenceBuilder --main README.rdoc
					#{rb_files.join(' ')}
	end
end
CLEAN.include 'doc/api'

def rdoc_to_html(file_name)
	require 'rdoc/markup/to_html'
	rdoc = RDoc::Markup::ToHtml.new
	rdoc.convert(File.read(file_name))
end

def haml(locals={})
	require 'haml'
	template = File.read('doc/template.haml')
	haml = Haml::Engine.new(template, :format => :html4, :attr_wrapper => '"')
	haml.render(Object.new, locals)
end

desc 'Build website HTML and stuff'
task 'doc:site' => ['doc/index.html']

file 'doc/index.html' => %w[README.rdoc doc/template.haml] do |file|
	File.open(file.name, 'w') do |file|
		file << haml(:title => 'SentenceBuilder', :content => rdoc_to_html('README.rdoc'))
	end
end
CLEAN.include 'doc/index.html'

# Gemspec Helpers ====================================================

file 'sentence_builder.gemspec' => FileList['{lib,spec}/**','Rakefile'] do |f|
	# read spec file and split out manifest section
	spec = File.read(f.name)
	parts = spec.split("  # = MANIFEST =\n")
	fail 'bad spec' if parts.length != 3
	# determine file list from git ls-files
	files = `git ls-files`.
		split("\n").
		sort.
		reject{ |file| file =~ /^\./ }.
		reject { |file| file =~ /^doc/ }.
		map{ |file| "    #{file}" }.
		join("\n")
	# piece file back together and write...
	parts[1] = "  s.files = %w[\n#{files}\n  ]\n"
	spec = parts.join("  # = MANIFEST =\n")
	File.open(f.name, 'w') { |io| io.write(spec) }
	puts "updated #{f.name}"
end
