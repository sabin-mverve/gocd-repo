# * ===========================================================================
# * Run this program from the command line with -
# * whenever --user douser --load-file config/schedule.rb --update-crontab
# * ===========================================================================
require 'logger'

this_cron_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

prog_file = File.expand_path(File.join(this_cron_root, 'program.rb'))
logs_dir = File.expand_path(File.join(this_cron_root, '..', 'logs'))

FileUtils.mkdir_p(logs_dir)

ENV['RACK_ENV'] = 'production' if `hostname`.chomp.include? 'elevatoz'

if ENV['RACK_ENV'] == 'production'
	log_file				= File.expand_path(File.join(logs_dir, 'publish_topics_lne.log'))
	LOGGER					= Logger.new(log_file, 'weekly')
	LOGGER.level			= Logger::INFO
	LOGGER.datetime_format	= "%d-%b-%y %I:%M:%S %p - %Z "
end

every :day, at: '1:30 am' do
	command "ruby #{prog_file} >> #{log_file}"
end