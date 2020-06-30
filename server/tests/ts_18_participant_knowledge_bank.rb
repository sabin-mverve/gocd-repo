require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - Get Mattress' do
		def setup
			create_participants_and_permissions
			create_product_and_coupons

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]
        end

        def test_get_mattress_invalid
            post "/participant/knowledge", {
                token: @token,
                answer1: '>100 kg',
                answer2: 'PU Foam',
                answer3: 'Parents',
                answer5: 'Extra Firm',
                answer6: 'Back Support',
                answer7: "Doesn't matter"
            }.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

        def test_get_mattress
            post "/participant/knowledge", {
                token: @token,
                answer1: '<50kg',
                answer2: 'Doesn\'t Matter',
                answer3: 'Parents',
                answer4: "<2 yrs",
                answer5: 'Firm',
                answer6: 'Comfort',
                answer7: "<10000"
            }.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end

    end

end