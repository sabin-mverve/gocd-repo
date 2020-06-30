require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context 'get - loginreport' do

		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			put "/helpdesk/requests/#{$help_dealer_request.id}", {
				token: @token,
				participant_type:'rsa',
				name: 'XXX',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				parent_id: $cso.id
			}.to_json

			delete "/helpdesk/requests/#{$help_dealer_request.id}", {token: @token}.to_json
			data = indifferent_data(JSON.parse(last_response.body))

			@registered_dealer = Participant.where(mobile: $help_dealer_request.mobile).first

			put "/helpdesk/requests/#{$help_rsa_request.id}", {
				token: @token,
				participant_type:'rsa',
				name: 'yyy',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				firmname: 'qwerty',
				tier: 'silver',
				code: 'qwerty103',
				parent_id: @registered_dealer.id

			}.to_json

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
		end

		def test_get_registered_report_valid
			get '/helpdesk/reports/registration' ,{page: 1, start: 0, limit: 25, token: @token}
            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
		end

		def test_download_registered_report_csv
            get '/helpdesk/reports/registration/download', {token: @token}
            assert_equal 200, last_response.status

        end

        def test_download_loginreport_csv_filter_daterange
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'from', value: date },
				{ property: 'to', value: date }
			].to_json

			get '/helpdesk/reports/loginreport/download', {token: @token, filter: filter}
			assert_equal 200, last_response.status
		end



	end
end