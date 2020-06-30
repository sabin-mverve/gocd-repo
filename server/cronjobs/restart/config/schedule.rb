# * ===========================================================================
# * Run this program from the command line from one directory up with -
# * whenever --user douser --load-file config/schedule.rb --update-crontab
# * ===========================================================================
this_cron_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
app_root = File.expand_path(File.join(this_cron_root, '../../..'))

every :reboot do
    command "cd #{app_root} && puma"
end
