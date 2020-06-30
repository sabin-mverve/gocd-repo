require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context "valid helpdesk login" do
		def setup
			create_helpdesk_user
		end

		def test_valid_helpdesk_login
			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][:token]
		end

		def test_invalid_helpdesk_login
			post "/helpdesk/auth/login", {email: 'random@email.com', password:  $hduser_password}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
        end

		def test_invalid_helpdesk_login_wrong_password
			post "/helpdesk/auth/login", {email: $hduser_email, password:  'randompassword'}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
	end

end

