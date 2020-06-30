require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - add to cart' do
		def setup
			create_participants_and_permissions
			create_rewards

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_add_to_cart_invalid_token
			post "/participant/cart", {token: '12131', quantity: 1, reward_id: $reward_100.id}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_add_to_cart_valid
			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values]

			get "/participant/dashboard", {token: @token}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 100, data[:values][:cart]
		end

		def test_add_to_cart_invalid
			post "/participant/cart", {token: @token, quantity: 10, reward_id: $reward_100.id}.to_json
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 500, last_response.status
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
    end

    context 'participant - remove from cart' do
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
		end

		def test_remove_from_cart
			delete "/participant/cart/#@cartitem_id", {token: @token}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]

			get "/participant/dashboard", {token: @token}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 0, data[:values][:cart]
		end
    end

    context 'participant - update quantity in cart - insufficient points' do
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
		end

		def test_update_cartitem_quantity_insufficient_points
			put "/participant/cart/#@cartitem_id", {token: @token, quantity: 10}.to_json
			assert_equal 500, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
    end

	context 'participant - update quantity in cart - valid number of points' do
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

		end

		def test_update_cartitem_quantity_sufficient_points
			put "/participant/cart/#@cartitem_id", {token: @token, quantity: 2}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal 2, data[:values][:quantity]

			get "/participant/dashboard", {token: @token}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, data[:values][:cart]
		end

    end

    context 'participant - get cart' do
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
		end

		def test_get_cart
			get "/participant/cart", {token: @token}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

    end

    context 'participant - add to cart - check against effective remaining points (earned - redeemed)' do
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

			post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json
		end

		def test_participant_invalid_add_to_cart_after_first_redeem
			post "/participant/cart", {token: @token, quantity: 10, reward_id: $reward_100.id}.to_json
			assert_equal 500, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

    end

    context 'participant - update quantity in cart - check against effective remaining points (earned - redeemed)' do
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

			post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@cartitem_id = data[:values][:id]

		end

		def test_participant_invalid_update_quantity_after_first_redeem
			put "/participant/cart/#@cartitem_id", {token: @token, quantity: 5}.to_json
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

    end

    context 'participant - update quantity when quantity is lessened - valid points' do
		def setup
			create_participants_and_permissions
			create_rewards

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			post "/participant/cart", {token: @token, quantity: 2, reward_id: $reward_100.id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@cartitem1_id = data[:values][:id]

		end

		def test_reduce_cartitem_quantity_sufficient_points
			put "/participant/cart/#@cartitem1_id", {token: @token, quantity: 1}.to_json
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

	end

end