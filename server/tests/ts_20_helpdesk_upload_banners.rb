require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context 'Helpdesk upload-banners' do

		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]
		end

		def test_upload_banners_image_one
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_one: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end

		def test_upload_banners_image_two
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_two: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end

		def test_upload_banners_image_three
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_three: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end

		def test_upload_banners_image_four
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_four: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end
	end

	context 'Helpdesk update-banners' do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_one: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			post "/helpdesk/banners", {
				token: @token,
				banner_two: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			post "/helpdesk/banners", {
				token: @token,
				banner_three: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			post "/helpdesk/banners", {
				token: @token,
				banner_four: Rack::Test::UploadedFile.new(filepath, mime_type),
			}
		end

		def test_update_banners_image_one
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_one: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end

		def test_update_banners_image_two
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_two: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end

		def test_update_banners_image_three
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_three: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end

		def test_update_banners_image_four
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_four: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

		end
	end

	context 'Helpdesk delete-banners' do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners", {
				token: @token,
				banner_one: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			post "/helpdesk/banners", {
				token: @token,
				banner_two: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			post "/helpdesk/banners", {
				token: @token,
				banner_three: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			post "/helpdesk/banners", {
				token: @token,
				banner_four: Rack::Test::UploadedFile.new(filepath, mime_type),
			}
		end

		def test_delete_banner_image_one
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners/deletebanner", {
				token: @token,
				banner_one: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
		end
		def test_delete_banner_image_two
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners/deletebanner", {
				token: @token,
				banner_two: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
		end

		def test_delete_banner_image_three
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners/deletebanner", {
				token: @token,
				banner_three: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
		end

		def test_delete_banner_image_four
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/banners/deletebanner", {
				token: @token,
				banner_four: Rack::Test::UploadedFile.new(filepath, mime_type),
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
		end
	end

	context 'Helpdesk get-banners' do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]
		end

		def test_get_banners
			get "/helpdesk/banners", {token: @token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil data[:values]
		end
	end
end