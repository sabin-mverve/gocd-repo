require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - add referral - invalid - user mobile exists, valid add referral' do
		def setup
			create_participants_and_permissions

			post "/participant/mobile", {mobile: $mobile2, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile2, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_participant_referral_invalid_user_mobile_exists
			post "/participant/refer", {
				token: @token,
				name: 'AAA',
				mobile: $mobile4
			}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_participant_referral_valid
			post "/participant/refer", {
				token: @token,
				name: 'AAA',
                mobile: '9999990000'
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal true, data[:values]
		end
    end

	context 'participant - add referral by CSO - invalid' do
		def setup
			create_participants_and_permissions

			post "/participant/mobile", {mobile: $mobile1, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile1, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_participant_referral_by_cso
			post "/participant/refer", {
				token: @token,
				name: 'AAA',
				mobile: $mobile4
			}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
	end
end