require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context 'get - loginreport' do

		def setup
			create_helpdesk_user
            create_participants_and_permissions


			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@ptoken = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile4, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile4, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@ptoken = data[:values][:token]

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @hd_token = data[:values][:token]

		end

		def test_get_loginreport_valid
			get '/helpdesk/reports/loginreport' ,{page: 1, start: 0, limit: 25, token: @hd_token}
            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
		end

		def test_download_loginreport_csv
            get '/helpdesk/reports/loginreport/download', {token: @hd_token}
            assert_equal 200, last_response.status

        end

        def test_download_loginreport_csv_filter_daterange
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'from', value: date },
				{ property: 'to', value: date }
			].to_json

			get '/helpdesk/reports/loginreport/download', {token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
		end



	end
end