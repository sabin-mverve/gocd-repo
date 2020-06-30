require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - get redemption history' do
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

		def test_participant_redemption_history_with_filter
			today = Date.today
			yesterday = today - 1

			from = yesterday.strftime("%Y-%m-%d")
			to = today.strftime("%Y-%m-%d")

			filter = [
				{ property: 'from', value: from } ,
				{ property: 'to', value: to } ,
			].to_json

			sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json

			get "/participant/order", {token: @token, page: 1, start: 0, limit: 2, filter: filter, sort: sorter}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
			assert_equal Array, data[:values].class

			assert_not_nil data[:values][0][:order_number]
			assert_not_nil data[:values][0][:points]
			assert_not_nil data[:values][0][:date]
			assert_not_nil data[:values][0][:num_items]
		end

	end

	context 'participant - get redemption history detail' do
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

			today = Date.today
			yesterday = today - 1
			tomorrow = today + 1
			from = yesterday.strftime("%Y-%m-%d")
			to = tomorrow.strftime("%Y-%m-%d")

			filter = [
				{ property: 'from', value: from } ,
				{ property: 'to', value: to } ,
			].to_json

			sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json

			get "/participant/order", {token: @token, page: 1, start: 0, limit: 2, filter: filter, sort: sorter}
			data = indifferent_data(JSON.parse(last_response.body))
			@order_id = data[:values][0][:id]
		end

		def test_participant_redemption_history_detail
			get "/participant/order/#@order_id", {token: @token}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][0][:id]
			assert_not_nil data[:values][0][:order_number]
			assert_not_nil data[:values][0][:quantity]
			assert_not_nil data[:values][0][:name]
			assert_not_nil data[:values][0][:model_number]
			assert_not_nil data[:values][0][:code]
			assert_not_nil data[:values][0][:brand]
			assert_not_nil data[:values][0][:description]
			assert_not_nil data[:values][0][:image]
			assert_not_nil data[:values][0][:points]
			# assert_not_nil data[:values][0][:category_id]
			# assert_not_nil data[:values][0][:category_name]
			# assert_not_nil data[:values][0][:sub_category_id]
			# assert_not_nil data[:values][0][:sub_category_name]
		end

	end

	context 'participant - get redemption history with detail items' do
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

			# filter = [ { property: 'status', value: 'redeemed' } ].to_json

			get "/participant/order", {token: @token, page: 1, start: 0, limit: 2}
			data = indifferent_data(JSON.parse(last_response.body))

			@order_id = data[:values][0][:id]
		end

		def test_participant_redemption_detail
			get "/participant/order/#@order_id/items", {token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))

			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end

	end

end