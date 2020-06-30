require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
    end

    context 'helpdesk - upload gallery images and thumbs' do
        def setup
            create_helpdesk_user

            post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
        end

        def test_helpdesk_upload_thumbs
            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/thumbs.zip'))
            mime_type = 'application/zip, application/octet-stream, application/x-zip-compressed, multipart/x-zip'

            post "/helpdesk/catalogue/gallery/thumbnails", {
				token: @token,
				zipfile: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]

        end

        def test_helpdesk_upload_images
            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/pics.zip'))
            mime_type = 'application/zip, application/octet-stream, application/x-zip-compressed, multipart/x-zip'

            post "/helpdesk/catalogue/gallery/images", {
				token: @token,
				zipfile: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]

        end

    end

    context 'helpdesk - get gallery images' do
        def setup
            create_helpdesk_user

            post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
        end

        def test_helpdesk_get_gallery_thumbnail
            get "/helpdesk/catalogue/gallery/thumbnails", {token: @token}

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
            assert_not_nil data[:values]
        end

        def test_helpdesk_get_gallery_images
            get "/helpdesk/catalogue/gallery/images", {token: @token}

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
            assert_not_nil data[:values]
        end

    end

end