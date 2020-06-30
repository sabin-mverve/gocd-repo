%w(
	yaml
	sequel
	dotenv
).each { |lib| require lib }

Dotenv.load
Dotenv.load ".env.#{ENV['RACK_ENV']}"


# * #######################################
# *        DEVELOPMENT CONFIGURATION
# * #######################################

namespace :db do
	desc "Postgres DB - enter version number or blank for latest"
	task :migrate, [:version] do |t, args|
		Sequel.extension :migration
		# db_file = File.expand_path(File.join(ENV['DB_FILE']))
		# db = Sequel.connect adapter: 'sqlite', database: db_file
		db = Sequel.connect adapter: 'postgres', database: ENV['PG_DB'], user: ENV['PG_USERNAME'], password: ENV['PG_PASSWORD']

		if args[:version]
			puts "Migrating to version #{args[:version]}"
			Sequel::Migrator.run(db, "server/migrations", target: args[:version].to_i)
		else
			puts "Migrating to latest"
			Sequel::Migrator.run(db, "server/migrations")
		end
	end

	desc "seed the database"
	task :seed do
		puts "Seeding Database"
		command = "bundle exec 'ruby ./seeder.rb'"
		puts exec command
	end

	desc "reset and seed the database"
	task :reset do
		Rake::Task['db:migrate'].invoke(0)
		Rake::Task['db:migrate'].reenable
		Rake::Task['db:migrate'].invoke
		# Rake::Task['db:migrate'].execute
		Rake::Task['db:seed'].invoke
		puts "** Done **"
	end

	desc "check database schema"
	task :latest do
		Sequel.extension :migration
		# db_file = File.expand_path(File.join(ENV['DB_FILE']))
		# db = Sequel.connect adapter: 'sqlite', database: db_file
		db = Sequel.connect adapter: 'postgres', database: ENV['PG_DB'], user: ENV['PG_USERNAME'], password: ENV['PG_PASSWORD']

		begin
			Sequel::Migrator.check_current(db, "server/migrations")
			puts "DB schema is latest"
		rescue
			puts "DB schema is not latest"
		end
	end
end

namespace :app do
	desc "test by test name: rake app:t test_get_states"
	task :t do |t, args|
		ENV['RACK_ENV'] = 'test'

		ARGV.each { |a| task a.to_sym do ; end }

		testname = ARGV[1]

		files = File.join('server', 'tests', 'ts_*.rb')
		test_files = Dir.glob(files)

		matches = test_files.collect do |filename|
			filename if !File.open(filename).grep(/\b#{testname}\b/).empty?
		end.compact

		if matches.count > 1
			puts
			matches.each { |f| puts f }
			puts
			abort "'#{testname}' exists in multiple test files"
		end

		filename = matches.first
		puts "Test file = #{filename}"
		command = "bundle exec 'ruby #{filename} -n #{testname}'"

		puts exec command
	end

	desc "test by number & name: rake app:tt 21 test_get_states"
	task :tt do |t, args|
		ENV['RACK_ENV'] = 'test'
		tests_dir = File.expand_path(File.join(__dir__, 'server/tests'))

		ARGV.each { |a| task a.to_sym do ; end }

		test_file_number = ARGV[1]

		files = File.join('server', 'tests', "ts_#{test_file_number}*.rb")
		test_files = Dir.glob(files)

		if test_files.empty?
			abort "Error - Invalid file number"
			abort
		end

		test_file = test_files.first
		testname = ARGV[2]
		if testname.nil?
			command = "bundle exec 'ruby #{test_file}'"
		else
			command = "bundle exec 'ruby #{test_file} -n #{testname}'"
		end

		puts exec command
	end

	desc "to test all apis"
	task :test do
		puts system "bundle exec 'rake -f rakefile_alltest.rb'"
	end

	desc "run app in development mode"
	task :dev do
		ENV['RACK_ENV'] = 'development'
		puts system("bundle exec 'puma'")
	end

	desc "run app in dev mode for mobile"
	task :mobile do
		ENV['RACK_ENV'] = 'mobile'
		puts system("bundle exec 'rackup -q server/app/config.ru -o 0.0.0.0 -p 9295'")
	end

end

def local? callers_array
	ret = false
	callers_array.each_with_index do |x, i|
		break if i > 50
		if (x.include?(__FILE__))
			ret = true
			break
		end
	end
	ret
end

# desc "create local fossilversion.txt file"
task :versionhtml do
	require 'open3'

	filename = 'fossilversion.txt'

	FileUtils.rm filename if File.exists? filename

	stdout, response, status = Open3.capture3("fossil info")
	if stdout.empty?
		output = 'not part of repository'
	else
		project = version = branch = nil
		arr = stdout.split("\n")
		arr.each_with_index do |a, i|
			if a.include? 'project-name:'
				project = a.split('project-name:')[1].strip
			elsif a.include? 'checkout:'
				version = a.split(' ')[1][0..10]
			elsif a.include? 'tags:'
				branch = a.split('tags:')[1].strip
			end
		end
		output = "<table width=100%><tr>\
			<td width=30%>
				#{project}
			</td>
			<td width=30%>
				#{branch}
			</td>
			<td width=30%>
				#{version}
			</td>
		</tr></table>".gsub("\t",'').gsub("\n", '')
	end

	file = File.open(filename, 'w')
	file.write(output)
	file.close
end



if ENV['RACK_ENV'] == 'development' or ENV['RACK_ENV'].to_s.empty?
	require 'sshkit'
	require 'sshkit/dsl'

	include SSHKit::DSL

	# * #######################################
	# *          STAGING CONFIGURATION
	# * #######################################

	user_host = 'douser@139.59.70.48'

	project_path = "/home/douser/projects/ElevatozLNDCentuary"

	participant_path = "#{project_path}/client/apps/LND"
	helpdesk_path = "#{project_path}/client/apps/HelpDesk"

	pid_file = "#{project_path}/pid/puma.pid"

	namespace :staging do
		desc "Database - checkout staging, reset, seed database, restart server"
		task :database do
			on user_host, in: :sequence do |host|
				with RACK_ENV: :staging do
					within project_path do
						execute(:pumactl, "-P #{pid_file} stop") if test "[ -f #{pid_file} ]"
						execute :fossil, "update staging"
						execute :rake, "versionhtml"
						execute :rake, 'db:reset'
						execute :puma, "-e staging -d"
					end
				end
			end
		end

		desc "Server - checkout staging version and do a bundle install"
		task :gems do
			on user_host, in: :sequence do |host|
				with RACK_ENV: :staging do
					within project_path do
						execute(:pumactl, "-P #{pid_file} stop") if test "[ -f #{pid_file} ]"
						execute :fossil, "update staging"
						execute :rake, "versionhtml"
						execute :bundle, "install --without development test"
						execute :puma, "-e staging -d"
					end
				end
			end
		end

		desc "Server - checkout staging version and restart"
		task :server do
			on user_host, in: :sequence do |host|
				with RACK_ENV: :staging do
					within project_path do
						execute(:pumactl, "-P #{pid_file} stop") if test "[ -f #{pid_file} ]"
						execute :fossil, "update staging"
						execute :rake, "versionhtml"
						execute :puma, "-e staging -d"
					end
				end
			end
		end

		desc "HelpDesk - checkout staging version and package"
		task :helpdesk do
			on user_host, in: :sequence do |host|
				with RACK_ENV: :staging do
					within helpdesk_path do
						execute :fossil, "update staging"
						execute :rake, "versionhtml"
						execute :sencha, "app build -c"
					end
				end
			end
		end

	end # * staging


	# * #######################################
	# *          PRODUCTION CONFIGURATION
	# * #######################################

	prod_user_host = 'douser@159.89.165.79' # Elevatoz Centuary LND
	prod_project_path = "/home/douser/project-production"
	prod_mobile_path = "#{prod_project_path}/client/apps/DF"
	prod_helpdesk_path = "#{prod_project_path}/client/apps/HelpDesk"

	prod_pid_file = "#{prod_project_path}/pid/puma.pid"

	namespace :production do
		desc "Database - checkout production, migrate to latest, restart server"
		task :database do
			on prod_user_host, in: :sequence do |host|
				with RACK_ENV: :production do
					within prod_project_path do
						execute(:pumactl, "-P #{prod_pid_file} stop") if test "[ -f #{prod_pid_file} ]"
						execute :fossil, "update production"
						execute :sequel, "-m ./server/migrations sqlite://#{ENV['DB_FILE']}"
						execute :puma, "-e production -d"
					end
				end
			end
		end

		desc "Server - checkout production version and restart"
		task :server do
			on prod_user_host, in: :sequence do |host|
				with RACK_ENV: :production do
					within prod_project_path do
						execute(:pumactl, "-P #{prod_pid_file} stop") if test "[ -f #{prod_pid_file} ]"
						execute :fossil, "update production"
						execute :puma, "-e production -d"
					end
				end
			end
		end

		# desc "Mobile - checkout production version and package"
		# task :mobile do
		# 	on prod_user_host, in: :sequence do |host|
		# 		with RACK_ENV: :production do
		# 			within prod_mobile_path do
		# 				execute :fossil, "update production"
		# 				execute :sencha, "app build -c"
		# 			end
		# 		end
		# 	end
		# end

		desc "HelpDesk - checkout production version and package"
		task :helpdesk do
			on prod_user_host, in: :sequence do |host|
				with RACK_ENV: :production do
					within prod_helpdesk_path do
						execute :fossil, "update production"
						execute :sencha, "app build -c"
					end
				end
			end
		end
	end # * production

end