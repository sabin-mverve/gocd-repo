require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'helpdesk - reports - points' do
		def setup
			create_participants_and_permissions
			create_helpdesk_user
			create_product_and_coupons


			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			# post "/participant/claim", {token: @token}.to_json
			post "/participant/claim/verify", {token: @token, serial_no: $coupon1_code}.to_json
			codes = [$coupon1_code, $coupon2_code]

			post "/participant/claim", {token: @token, serial_no: codes}.to_json

		end

		def test_get_points
            get '/helpdesk/reports/points', {page: 1, start: 0, limit: 25, token: @hd_token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
			# last = data[:values].last
			# assert_not_nil last[:id]
			# assert_not_nil last[:name]
			# assert_not_nil last[:mobile]
			# assert_not_nil last[:city_id]
			# assert_not_nil last[:state_id]
			# assert_not_nil last[:city]
			# assert_not_nil last[:state]
			# assert_not_nil last[:earned_points]
			# assert_not_nil last[:redeemed_points]
			# assert_not_nil last[:total_earned_points]
			# assert_not_nil last[:total_redeemed_points]
			# assert_not_nil last[:total_balance_points]
			# assert_not_nil last[:role]

		end

		def test_get_points_filter_by_mobile
			filter = [
				{ property: 'query', value: '911234567890' }
			].to_json

			get '/helpdesk/reports/points', {page: 1, start: 0, limit: 25, token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
			# first = data[:values].first

			# assert_equal '911234567890',first[:mobile]
		end

		def test_get_points_filter_by_state_city
			filter = [
				{ property: 'state', value: 10 },
				{ property: 'city', value: 2878 }
			].to_json

			get '/helpdesk/reports/points', {page: 1, start: 0, limit: 25, token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end

		def test_get_points_filter_by_date
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'fromdate', value: date },
				{ property: 'todate', value: date }
			].to_json

			get '/helpdesk/reports/points', {page: 1, start: 0, limit: 25, token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end

		def test_download_points_csv
			get '/helpdesk/reports/points/download', {token: @hd_token}
			assert_equal 200, last_response.status
		end

		def test_download_points_csv_filter_by_mobile
			filter = [
				{ property: 'query', value: '911234567890' }
			].to_json

			get '/helpdesk/reports/points/download', {token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
		end

		def test_download_points_csv_filter_by_state_city
			filter = [
				{ property: 'state', value: 10 },
				{ property: 'city', value: 2878 }
			].to_json

			get '/helpdesk/reports/points/download', {token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
		end

		def test_download_points_csv_filter_by_date
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'fromdate', value: date },
				{ property: 'todate', value: date }
			].to_json

			get '/helpdesk/reports/points/download', {token: @hd_token, filter: filter}
			assert_equal 200, last_response.status
		end

	end

end