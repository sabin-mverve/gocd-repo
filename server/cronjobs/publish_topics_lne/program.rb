# * ====================================================
# * This program has to be run via config/schedule.rb
# * ====================================================

%w(
	dotenv
	csv
	fileutils
	securerandom
	bundler
).each { |lib| require lib }
require 'logger'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	ENV['RACK_ENV'] = 'production' if `hostname`.chomp.include? 'elevatoz'

	Dotenv.load ".env.#{ENV['RACK_ENV']}"

	require './server/app/models'
	require './server/app/sms'
end

today = Date.today

Topic.where(month: today.month, year: today.year).each do |t|
	if  t.questions.count > 1
		DB.transaction do
			t.update(published: 1)
		end
	end
end