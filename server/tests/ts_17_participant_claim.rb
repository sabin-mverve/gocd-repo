require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - make claims' do
		def setup
			create_participants_and_permissions
			create_product_and_coupons

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_verify_coupon_invalid_code
			post "/participant/claim/verify", {token: @token, serial_no: 'alsjfaskjljas'}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_verify_coupon_valid_code
			post "/participant/claim/verify", {token: @token, serial_no: $coupon1_code}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][:points]
		end

		def test_make_claim_invalid_code
			codes = ['alsjfaskjljas', $coupon2_code]

			post "/participant/claim", {token: @token, serial_no: codes}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_make_claim_valid_codes
			codes = [$coupon1_code, $coupon2_code]

			post "/participant/claim", {token: @token, serial_no: codes}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

end