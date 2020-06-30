require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

Dotenv.load
Dotenv.load ".env.#{ENV['RACK_ENV']}"

logs_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'logs'))
FileUtils.mkdir_p(logs_dir)

public_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'rewards', 'categories'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'rewards', 'products', 'pics'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'rewards', 'products', 'thumbs'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'gallery', 'products', 'pics'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'gallery', 'products', 'thumbs'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'attachments'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'materials'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'certificates'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'banners'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads','reports'))




if ENV['RACK_ENV'] == 'development'
	LOGGER					= Logger.new(STDOUT)
	LOGGER.level			= Logger::INFO
	LOGGER.datetime_format	= "%d-%b-%y %I:%M:%S %p - %Z "
elsif ENV['RACK_ENV'] == 'production' or ENV['RACK_ENV'] == 'staging'
	log_file				= File.expand_path(File.join(logs_dir, 'common.log'))
	LOGGER					= Logger.new(log_file, 'weekly')
	LOGGER.level			= Logger::INFO
	LOGGER.datetime_format	= "%d-%b-%y %I:%M:%S %p - %Z "
end

require_relative 'routes'

builder = Rack::Builder.new do

	use Rack::Cors do
		allow do
			origins '*', 'localhost'
			resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
		end
	end

	run App.app
end

run builder.to_app