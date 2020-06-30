require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'helpdesk - reports - redemptions' do
		def setup
			create_participants_and_permissions
			create_rewards
			create_helpdesk_user
			create_product_and_coupons


			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			post "/participant/claim/verify", {token: @token, serial_no: $coupon1_code}.to_json
			codes = [$coupon1_code, $coupon2_code]

			post "/participant/claim", {token: @token, serial_no: codes}.to_json

			post "/participant/cart", {token: @token, quantity: 1, reward_id: $reward_100.id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))

			get "/participant/address", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@address_id = data[:values][0][:id]

			post "/participant/cart/checkout", {token: @token, address_id: @address_id}.to_json
		end

		def test_get_redemptions
			get '/helpdesk/reports/redemption', {page: 1, start: 0, limit: 25, token: @hd_token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
			record = data[:values].last

			assert_not_nil record[:redemptionid]
			assert_not_nil record[:created_at]
			assert_equal 'rsa', record[:role]
			assert_equal '911234567897', record[:mobile]
			# assert_equal 'p1@email.com', record[:email]
			# assert_equal 100, record[:unit_points]
			# assert_equal 1, record[:quantity]
			assert_equal 'BBB 2', record[:address1]
			assert_equal 'Bangalore', record[:city]
			assert_equal 'Karnataka', record[:state]
			assert_equal '3213222', record[:pincode]
		end

		def test_get_redemptions_filter_by_mobile
			filter = [
				{ property: 'query', value: '999999999999' }
			].to_json

			get '/helpdesk/reports/redemption', {page: 1, start: 0, limit: 25, token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class

			record = data[:values].last
			if record
				assert_not_nil record[:redemptionid]
				assert_not_nil record[:created_at]
				assert_equal 'rsa', record[:role]
				assert_equal '911234567897', record[:mobile]
				# assert_equal 'p1@email.com', record[:email]
				# assert_equal 100, record[:unit_points]
				# assert_equal 1, record[:quantity]
				assert_equal 'BBB 2', record[:address1]
				assert_equal 'Bangalore', record[:city]
				assert_equal 'Karnataka', record[:state]
				assert_equal '3213222', record[:pincode]
			end
		end

		# def test_get_redemptions_filter_by_status
		# 	filter = [
		# 		{ property: 'status', value: 'redeemed' }
		# 	].to_json

		# 	get '/helpdesk/reports/redemption', {page: 1, start: 0, limit: 25, token: @hd_token, filter: filter}
		# 	assert_equal 200, last_response.status
		# 	data = indifferent_data(JSON.parse(last_response.body))
		# 	assert_not_nil data
		# 	assert_equal true, data[:success]
		# 	assert_equal Array, data[:values].class

		# 	record = data[:values].last
		# 	assert_not_nil record[:id]
		# 	assert_not_nil record[:created_at]
		# 	assert_not_nil record[:order_number]
		# 	assert_equal 'redeemed', record[:status]
		# 	assert_equal 'AAA', record[:name]
		# 	assert_equal 'carpenter', record[:role]
		# 	assert_equal '999999999999', record[:mobile]
		# 	assert_equal 'p1@email.com', record[:email]
		# 	assert_equal 100, record[:points]
		# 	assert_equal 1, record[:quantity]
		# 	assert_equal 'AAA 1', record[:address1]
		# 	assert_equal 'Bangalore', record[:city]
		# 	assert_equal 'Karnataka', record[:state]
		# 	assert_equal '123456', record[:pincode]
		# 	assert_equal 'app', record[:mode]
		# end

		def test_get_redemptions_filter_by_date
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'fromdate', value: date },
				{ property: 'todate', value: date }
			].to_json

			get '/helpdesk/reports/redemption', {page: 1, start: 0, limit: 25, token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class

			record = data[:values].last
			assert_not_nil record[:redemptionid]
			assert_not_nil record[:created_at]
			assert_equal 'rsa', record[:role]
			assert_equal '911234567897', record[:mobile]
			# assert_equal 'p1@email.com', record[:email]
			# assert_equal 100, record[:unit_points]
			# assert_equal 1, record[:quantity]
			assert_equal 'BBB 2', record[:address1]
			assert_equal 'Bangalore', record[:city]
			assert_equal 'Karnataka', record[:state]
			assert_equal '3213222', record[:pincode]
		end

		def test_download_redemptions_csv_filter_by_mobile
			filter = [
				{ property: 'query', value: '911234567897' }
			].to_json

			get '/helpdesk/reports/redemption/download', {token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
		end

		def test_get_redemptions_correct_order_number
			get '/helpdesk/reports/redemption', {page: 1, start: 0, limit: 25, token: @hd_token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_not_nil data
			assert_equal true, data[:success]
			records = data[:values]
			records.each do |rec|
				first_order_number = rec[:order_number].scan(/.{4}/)
				assert_equal 'CLND', first_order_number[0]
			end
		end

		# def test_download_redemptions_csv_filter_by_status
		# 	filter = [
		# 		{ property: 'status', value: 'redeemed' }
		# 	].to_json

		# 	get '/helpdesk/reports/redemption/download', {token: @hd_token, filter: filter}
		# 	assert_equal 200, last_response.status
		# end

		# def test_download_redemptions_csv_filter_by_mode
		# 	filter = [
		# 		{ property: 'mode', value: 'app' }
		# 	].to_json

		# 	get '/helpdesk/reports/redemption/download', {token: @hd_token, filter: filter}
		# 	assert_equal 200, last_response.status
		# end
	end

end