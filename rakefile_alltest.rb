require 'rake/testtask'
Rake::TestTask.new(:alltest) do |t|
	ENV['RACK_ENV'] = 'alltest'
	t.test_files = FileList['server/tests/**/ts_*.rb']
	# t.verbose = true
	t.verbose = false
	t.warning = false
end

task :default => [:alltest]