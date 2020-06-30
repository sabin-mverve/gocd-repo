puts "---------------"
puts "ENV - #{ENV['RACK_ENV']}"

require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

%w(
    defaults
	models
	sms
	mailer
).each { |l| require_relative l}

class App < Roda
	plugin :multi_route

    route do |r|
        body = request.body.read
		request.body.rewind
		data = JSON.parse(body) rescue {}
        data = indifferent_data(data)

		if defined? LOGGER
			LOGGER.info "#{request.request_method} #{request.path}"
			LOGGER.info "#{params} #{data}"
			LOGGER.info "#{data}"
		elsif ENV['RACK_ENV'] != 'alltest'
			if ENV['RACK_ENV'] != 'alltest'
				puts "\n=== request info ===\n#{request.request_method} #{request.path}\n------------------ params -------------------------\n#{params}\n------------------ data -------------------------\n#{data}\n"
			end
		end

		require_relative 'participant'
		require_relative 'helpdesk'

		r.multi_route

    end

end