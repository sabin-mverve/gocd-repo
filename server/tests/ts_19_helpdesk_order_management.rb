require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
    end

    context 'Helpdesk get all orders for a client' do
        def setup
            create_participants_and_permissions
            create_helpdesk_user
            create_rewards

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_200.id}.to_json

			get "/participant/address", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@address_id = data[:values][0][:id]

            post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json

            post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @hd_token = data[:values][:token]

        end

        def test_helpdesk_get_users_orders
            get "/helpdesk/orders", {token: @hd_token,page: 1, start: 0, limit: 10}
            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
			assert_not_nil data[:total]
            assert_not_nil data[:values]
            assert_equal Array, data[:values].class

            assert_not_nil data[:values][0][:order_number]
			assert_not_nil data[:values][0][:points]
			assert_not_nil data[:values][0][:date]
			assert_not_nil data[:values][0][:num_items]
        end

		def test_helpdesk_get_orders_with_filters
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

            get "/helpdesk/orders", {token: @hd_token, page: 1, limit: 2, filter: filter, sorter: sorter}
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

        def test_helpdesk_get_orders_with_name_filter
            filter = [ { property: 'query', value: 'AAA' }].to_json

            sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json

            get "/helpdesk/orders", {token: @hd_token, page: 1, limit: 2, filter: filter, sorter: sorter}
            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
            assert_not_nil data[:total]
            assert_not_nil data[:values]
            assert_equal Array, data[:values].class
        end

    end

    context 'Helpdesk update order status' do
        def setup
            create_participants_and_permissions
            create_helpdesk_user
            create_rewards

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_200.id}.to_json

			get "/participant/address", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@address_id = data[:values][0][:id]

            post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json

            post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @hd_token = data[:values][:token]

            get "/helpdesk/orders", {token: @hd_token,page: 1, start: 0, limit: 10}
            data = indifferent_data(JSON.parse(last_response.body))
            @order = data[:values][0]
            @sub_order_first = @order[:items].first
        end

        def test_helpdesk_update_orders

            sub_orders = [{
                suborder_number: @sub_order_first[:suborder_number],
                status: 'dispatched'
            }].to_json


            put "/helpdesk/orders/#{@order[:id]}",{
                token: @hd_token,
                sub_orders: sub_orders
            }.to_json

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
            assert_not_nil data[:values]
            # puts "----------#{__LINE__} ----------- \n data =>>> #{data}"
        end
    end

    context 'Helpdesk cancel order' do
        def setup
            create_participants_and_permissions
            create_helpdesk_user
            create_rewards
            create_product_and_coupons

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            codes = [$coupon1_code, $coupon2_code]

			post "/participant/claim", {token: @token, serial_no: codes}.to_json

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_200.id}.to_json

			get "/participant/address", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@address_id = data[:values][0][:id]

            post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json

            post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @hd_token = data[:values][:token]

            get "/helpdesk/orders", {token: @hd_token,page: 1, start: 0, limit: 10}
            data = indifferent_data(JSON.parse(last_response.body))
            @order = data[:values][0]
            @sub_order_first = @order[:items].first

        end

        def test_helpdesk_admin_cancel_order

            sub_orders = [{
                suborder_number: @sub_order_first[:suborder_number],
                status: 'canceled'
            }].to_json

            put "/helpdesk/orders/#{@order[:id]}",{
                token: @hd_token,
                sub_orders: sub_orders
            }.to_json

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
            assert_not_nil data[:values]
        end
    end

    context 'Elevatoz Admin - Update status and Courier details' do
        def setup
            create_participants_and_permissions
            create_helpdesk_user
            create_rewards

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

            create_orders

            post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @hd_token = data[:values][:token]

            get "/helpdesk/orders", {token: @hd_token,page: 1, start: 0, limit: 10}
            data = indifferent_data(JSON.parse(last_response.body))
            @order = data[:values][0]
            @sub_order_first = @order[:items].first
            @sub_order_last = @order[:items].last
        end

        def test_helpdesk_update_status_and_courier_details
            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/order_status_update_master.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "/helpdesk/orders",{
				token: @hd_token,
                file: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
            assert_not_nil data[:values]
        end
    end
end