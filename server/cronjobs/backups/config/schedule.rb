# * ===========================================================================
# * Run this program from the command line with -
# * whenever --user douser --load-file config/schedule.rb --update-crontab
# * ===========================================================================
require 'logger'

this_cron_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

prog_file = File.expand_path(File.join(this_cron_root, 'program.rb'))
logs_dir = File.expand_path(File.join(this_cron_root, '..', 'logs'))

FileUtils.mkdir_p(logs_dir)

log_file				= File.expand_path(File.join(logs_dir, 'backup_cron.log'))
LOGGER					= Logger.new(log_file, 'weekly')
LOGGER.level			= Logger::INFO
LOGGER.datetime_format	= "%d-%b-%y %I:%M:%S %p - %Z "

# * 4 am and 8 pm IST
every :day, at: ['10:30 pm', '2:30 pm'] do
	command "ruby #{prog_file} >> #{log_file}"
end