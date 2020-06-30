require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
    end

    context "Helpdesk - Upload Coupon" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

		end

		def test_helpdesk_upload_coupons
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/couponsheet.valid.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "helpdesk/coupons",{
				token: @token,
                file: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
            assert_not_nil data[:values]
		end

		def test_helpdesk_upload_coupons_invalid
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/couponsheet.invalids.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "helpdesk/coupons",{
				token: @token,
                file: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
            assert_not_nil data[:values]
		end

	end

	context "Helpdesk -  get Coupon" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]


			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/couponsheet.valid.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "helpdesk/coupons",{
				token: @token,
                file: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

		end

		def test_get_coupon_invalid_token
			get "helpdesk/coupons", {page: 1, start: 0, limit: 25, token: '123'}
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_helpdesk_get_coupon
			get "helpdesk/coupons",{
				token: @token,
				page: 1,
				start: 0,
				limit: 25
			}

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
			assert_not_nil data[:values]
			assert_true data[:values].is_a? Array

			first = data[:values].first
			assert_not_nil first[:material]
            assert_not_nil first[:serial_no]
            assert_not_nil first[:status]
            assert_not_nil first[:created_at]
		end

		def test_helpdesk_coupon_by_status
			filter = [
				{ property: 'status', value: 'active' }
			].to_json

			get "helpdesk/coupons",{
				token: @token,
				page: 1,
				start: 0,
				limit: 25,
				filter: filter
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
            assert_true data[:values].is_a? Array
		end

		def test_helpdesk_filter_coupon_by_date
			today = Date.today
			yesterday = today - 1

			from = yesterday.strftime("%Y-%m-%d")
            to = today.strftime("%Y-%m-%d")

			filter = [ { property: 'from', value: from } , { property: 'to', value: to } ].to_json

			get "helpdesk/coupons",{
				token: @token,
				page: 1,
				start: 0,
				limit: 25,
				filter: filter
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
            assert_true data[:values].is_a? Array
		end

		def test_download_coupon_csv
            get "helpdesk/coupons/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10}
			assert_equal 200, last_response.status
		end

        def test_download_coupon_csv_filter_by_date
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'fromdate', value: date },
				{ property: 'todate', value: date }
			].to_json

            get "helpdesk/coupons/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
        end

	end
end