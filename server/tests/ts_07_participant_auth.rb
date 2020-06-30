require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context "valid mobile number - inactive participant" do
		def setup
			create_helpdesk_user
			create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			put "/helpdesk/users/#{$participant_id}", {token: @hd_token, active: false}
		end

		def test_verify_valid_mobile_number_inactive_participant
			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
	end

	context 'validate mobile number' do
		def setup
			create_participants_and_permissions
		end

		def test_verify_invalid_mobile_number
			post "/participant/mobile", {mobile: '1112223334'}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_verify_valid_mobile_number
			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "validate otp - inactive participant" do
		def setup
			create_helpdesk_user
			create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json

			put "/helpdesk/users/#{$participant_id}", {token: @hd_token, active: false}
		end

		def test_verify_valid_mobile_number_valid_otp_inactive_participant
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
	end

	context 'validate otp' do
		def setup
			create_participants_and_permissions
			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
		end

		def test_verify_invalid_mobile_number_invalid_otp
			post "/participant/login", {mobile: '1112223334', otp: '123123', player_id: $player_id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_verify_invalid_mobile_number_valid_otp
			post "/participant/login", {mobile: '1112223334', otp: $otp, player_id: $player_id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_verify_valid_mobile_number_invalid_otp
			post "/participant/login", {mobile: $mobile3, otp: '123123', player_id: $player_id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_verify_invalid_otp_expired
			# OTP is set to expire after 1 seconds in test
			sleep 1
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_verify_valid_mobile_number_valid_otp
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][:name]
			assert_not_nil data[:values][:token]
			assert_not_nil data[:values][:role]
			assert_not_nil data[:values][:permission]
		end

	end

	context 'validate otp' do
		def setup
			create_participants_and_permissions
			post "/participant/mobile", {mobile: $mobile3, player_id: $player2_id}.to_json
		end

		def test_verify_valid_mobile_number_valid_otp
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player2_id}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][:name]
			assert_not_nil data[:values][:token]
			assert_not_nil data[:values][:role]
			assert_not_nil data[:values][:permission]
		end

	end


end

