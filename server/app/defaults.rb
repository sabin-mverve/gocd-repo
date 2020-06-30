%w(
	yaml
	csv
).each { |lib| require lib }


class App < Roda
	plugin :indifferent_params
	plugin :json
	plugin :multi_route

	plugin :not_found
	plugin :error_handler
	plugin :all_verbs

	plugin :h

	not_found do
		404
	end

	def indifferent_data(data)
		case data
		when Hash
			hash = Hash.new{|h, k| h[k.to_s] if Symbol === k}
			data.each{|k, v| hash[k] = indifferent_data(v)}
			hash
		when Array
			data.map{|x| indifferent_data(x)}
		else
			data
		end
	end

	def true?(obj)
		obj.to_s == "true"
	end

	error do |e|
		message = ""
		message += "\n========ERROR========\n#{request.request_method} #{request.path}\n"
		message += e.message
		# message += "\n"
		e.backtrace.each_with_index do |x, i|
			break if (i > 5)
			parent_directory = File.expand_path(File.join(File.dirname(__FILE__), '..'))
			if x.include?(parent_directory)
				message += "\n#{x}"
				# puts("\t\t#{x}")
			end
		end
		message += "\n"

		if defined? LOGGER
			LOGGER.error(message)
		else
			puts message if ENV['RACK_ENV'] != 'alltest'
		end

		{
			:success => false,
			:error => e.message
		}.to_json
	end
end