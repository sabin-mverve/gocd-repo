require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context 'get - quizreport' do

		def setup
			create_helpdesk_user
            create_participants_and_permissions


			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@ptoken = data[:values][:token]

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @hd_token = data[:values][:token]

		end

		def test_get_quizreport_valid
			get '/helpdesk/reports/quiz' ,{page: 1, start: 0, limit: 25, token: @hd_token}
            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
		end

		def test_download_quizreport_csv
            get '/helpdesk/reports/quiz/download', {token: @hd_token}
            assert_equal 200, last_response.status

        end

        def test_download_quizreport_csv_filter_daterange
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'from', value: date },
				{ property: 'to', value: date }
			].to_json

			get '/helpdesk/reports/quiz/download', {token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
		end



	end
end