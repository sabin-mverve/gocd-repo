require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'helpdesk - get user earn history' do
		def setup
			create_participants_and_permissions
			create_rewards

			create_helpdesk_user

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

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get '/helpdesk/users', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			# @user = data[:values][0]
			@user = nil
			data[:values].each do |part|
				if part[:mobile] == $mobile3
					@user = part
					break
				end
			end

		end

		def test_get_user_earnhistory_with_filter
			today = Date.today
			yesterday = today - 1

			from = yesterday.strftime("%Y-%m-%d")
			to = today.strftime("%Y-%m-%d")

			filter = [
				{ property: 'from', value: from },
				{ property: 'to', value: to },
				# {property: 'type', value: nil}
			].to_json

			sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json

			get "/helpdesk/users/#{@user[:id]}/earnhistory", {token: @token, page: 1, start: 0, limit: 10, filter: filter, sort: sorter}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
			assert_equal Array, data[:values].class
        end

        def test_get_user_earnhistory
            get "/helpdesk/users/#{@user[:id]}/earnhistory", {token: @token, page: 1, start: 0, limit: 10}
			assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
			assert_equal Array, data[:values].class
		end

		def test_user_redemption_history_without_filter

			get "/helpdesk/users/#{@user[:id]}/redemptionhistory", {token: @token, page: 1, start: 0, limit: 2}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]

			assert_not_nil data[:values][0][:order_number]
			assert_not_nil data[:values][0][:points]
			assert_not_nil data[:values][0][:date]
			assert_not_nil data[:values][0][:num_items]
			assert_not_nil data[:values][0][:name]
			assert_not_nil data[:values][0][:mobile]
			assert_not_nil data[:values][0][:address1]
			assert_not_nil data[:values][0][:city]
			assert_not_nil data[:values][0][:state]
			assert_not_nil data[:values][0][:pincode]
		end

		def test_user_redemption_history_with_filter
			today = Date.today
			yesterday = today - 1

			from = yesterday.strftime("%Y-%m-%d")
			to = today.strftime("%Y-%m-%d")

			filter = [
				{ property: 'from', value: from },
				{ property: 'to', value: to },
				# { property: 'status', value: 'redeemed' }
			].to_json

			sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json

			get "/helpdesk/users/#{@user[:id]}/redemptionhistory", {token: @token, page: 1, start: 1, limit: 2, filter: filter, sort: sorter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
			assert_equal Array, data[:values].class

			assert_not_nil data[:values][0][:order_number]
			assert_not_nil data[:values][0][:points]
			assert_not_nil data[:values][0][:date]
		end


	end


end
