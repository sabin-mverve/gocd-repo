require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context "Add topics" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

		end

		def test_add_topic_valid
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			today = Date.today
			post "/helpdesk/lne/topics", {
				month: today.month,
				year: today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Get topics" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
			mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
		end

		def test_get_topic_valid
			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][0][:month]
			assert_not_nil data[:values][0][:year]
			assert_not_nil data[:values][0][:topic]
			assert_not_nil data[:values][0][:published]
			assert_not_nil data[:values][0][:questions]
		end

		def test_get_topic_valid_filter

			filter = [
				{ property: 'month', value: @today.month} ,
				{ property: 'year', value: @today.year} ,
			].to_json

			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25, filter: filter, token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][0][:month]
			assert_not_nil data[:values][0][:year]
			assert_not_nil data[:values][0][:topic]
			assert_not_nil data[:values][0][:published]
			assert_not_nil data[:values][0][:questions]
		end

		def test_get_topic_valid_filter_by_topic
			filter = [
				{ property: 'query', value: "Mattress" }
			].to_json

			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25, filter: filter, token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			if data[:values][0]
				assert_not_nil data[:values][0][:month]
				assert_not_nil data[:values][0][:year]
				assert_not_nil data[:values][0][:topic]
				assert_not_nil data[:values][0][:published]
				assert_not_nil data[:values][0][:questions]
			end


		end
	end

	context "Update topics" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
			mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			attachments = [
				Rack::Test::UploadedFile.new(filepath, mime_type),
				Rack::Test::UploadedFile.new(filepath, mime_type)
			]

			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}

			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]
		end

		def test_update_topic_valid
			post "/helpdesk/lne/topics/#{@record[:id]}", {
				month: 10,
				topic:'Mattress',
				token:@token,
				save_attachments:'[]'
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][:month]
			assert_not_nil data[:values][:year]
			assert_not_nil data[:values][:topic]
			assert_not_nil data[:values][:published]
		end
	end

	context "Delete topics" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
			mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			attachments = [
				Rack::Test::UploadedFile.new(filepath, mime_type),
				Rack::Test::UploadedFile.new(filepath, mime_type)
			]

			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]
		end

		def test_delete_topic_valid
			delete "/helpdesk/lne/topics/#{@record[:id]}", {token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end
end