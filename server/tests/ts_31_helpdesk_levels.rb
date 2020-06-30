require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context "Add levels" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

		end

		def test_add_level_valid
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			today = Date.today
			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',
				token:@token
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

		def test_add_level_valid_inorder_material
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			today = Date.today
			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',

				token:@token
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Get titles" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
			mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			@today = Date.today
			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',

				token:@token
			}

			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title2',
				description:'Electronicstopic2',
				published: false,
				attempted: false,
					material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
					material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
					material_03: '12121212',

				token:@token
			}

		end

		def test_get_titles_valid
			get "/helpdesk/levels/titles", {level:1,page: 1, start: 0, limit: 25,token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][0][:title]
			assert_not_nil data[:values][0][:description]
			assert_not_nil data[:values][0][:level]
			assert_not_nil data[:values][0][:published]
			assert_not_nil data[:values][0][:questions]
		end

		def test_get_title_valid_filter

			filter = [
				{ property: 'query', value: 'title2' }
			].to_json

			get "/helpdesk/levels/titles", {level:1 ,page: 1, start: 0, limit: 25, filter: filter, token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_not_nil data[:values][0][:title]
			assert_not_nil data[:values][0][:description]
			assert_not_nil data[:values][0][:level]
			assert_not_nil data[:values][0][:published]
			assert_not_nil data[:values][0][:questions]
		end

	end

	context "Update titles" do
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
			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',
				token:@token
			}

			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title2',
				description:'Electronics2',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',

				token:@token
			}

			get "/helpdesk/levels/titles", {level:1, page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]
		end

		def test_update_title_valid


			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
			mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			post "/helpdesk/levels/titles/#{@record[:level_title_id]}", {
				title: 'test title 23 updated',
				description:'Mattress level_title_id level_title_id ',
				token:@token,
				saved_materials: [].to_json,
				material_04: Rack::Test::UploadedFile.new(filepath, mime_type)
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][:title]
			assert_not_nil data[:values][:description]
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