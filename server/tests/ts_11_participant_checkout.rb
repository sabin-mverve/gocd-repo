require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - add to cart - checkout' do
		def setup
			create_participants_and_permissions
			create_rewards

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@cartitem_id = data[:values][:id]

			get "/participant/address", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@address_id = data[:values][0][:id]

		end

		def test_participant_checkout
			post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

	end

	context 'participant - add to cart, update quantity - checkout' do
		def setup
			create_participants_and_permissions
			create_rewards

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@cartitem_id = data[:values][:id]

			get "/participant/address", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@address_id = data[:values][0][:id]

			put "/participant/cart/#@cartitem_id", {token: @token, quantity: 2}.to_json

			get "/participant/dashboard", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@balance_points = data[:values][:balance]
		end

		def test_participant_update_cart_checkout
			post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]

			get "/participant/dashboard", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_equal @balance_points, data[:values][:balance]

		end
	end

end