require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end


	context "Helpdesk Request Upload excel" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

		end

		def test_helpdesk_upload_users
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/User Enrollment.valid.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "helpdesk/requests",{
				token: @token,
                file: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
            }

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert data[:success]
            assert_not_nil data[:values]
		end

		def test_helpdesk_upload_users_invalid
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/User Enrollment.invalids.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "helpdesk/requests",{
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

	context "Helpdesk Request get users" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]


			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/User Enrollment.valid.xlsx'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "helpdesk/requests",{
				token: @token,
                file: Rack::Test::UploadedFile.new(filepath, mime_type, binary = true)
			}
			data = indifferent_data(JSON.parse(last_response.body))
		end

		def test_get_helpdesk_requests_invalid_token
			get "/helpdesk/requests", {page: 1, start: 0, limit: 25, token: '123'}
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_helpdesk_request_get_users
			get "/helpdesk/requests",{
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
            assert_not_nil first[:status]
            assert_not_nil first[:mobile]
            assert_not_nil first[:created_at]
            assert_not_nil first[:participant_type]
            assert_not_nil first[:name]
            assert_not_nil first[:pincode]
            assert_not_nil first[:store_name]
            assert_not_nil first[:city_name]
            assert_not_nil first[:state_name]
		end

		def test_helpdesk_request_filter_users_by_status
			filter = [
				{ property: 'status', value: 'complete' }
			].to_json

			get "/helpdesk/requests",{
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

        def test_helpdesk_request_search_users_by_name
			filter = [
				{ property: 'query', value: 'priya' }
            ].to_json

			get "/helpdesk/requests",{
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
            # puts "----------#{__LINE__} ----------- \n data =>>> #{data}"
        end

        def test_helpdesk_request_search_users_by_mobile
			filter = [
				{ property: 'query', value: '8867510780' }
            ].to_json

			get "/helpdesk/requests",{
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
            # puts "----------#{__LINE__} ----------- \n data =>>> #{data}"
		end

		def test_helpdesk_request_filter_users_by_role
			filter = [
				{ property: 'participant_type', value: 'distributor' }
			].to_json

			get "/helpdesk/requests",{
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

		def test_helpdesk_request_filter_users_by_date
			today = Date.today
			yesterday = today - 1

			from = yesterday.strftime("%Y-%m-%d")
            to = today.strftime("%Y-%m-%d")

			filter = [ { property: 'from', value: from } , { property: 'to', value: to } ].to_json

			get "/helpdesk/requests",{
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

		# def test_get_helpdesk_requests_filter_by_type
		# 	filter = [
		# 		{ property: 'type', value: 'sms' }
		# 	].to_json
		# 	get '/helpdesk/requests', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
		# 	assert_equal 200, last_response.status
		# 	data = indifferent_data(JSON.parse(last_response.body))
		# 	assert_not_nil data
		# 	assert_equal true, data[:success]
		# 	assert_true data[:values].is_a? Array

		# 	first = data[:values].first
		# 	assert_equal 'incomplete', first[:status]
        # end

		def test_download_requests_csv
            get "helpdesk/requests/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10}
			assert_equal 200, last_response.status
		end

        def test_download_requests_csv_filter_by_date
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'fromdate', value: date },
				{ property: 'todate', value: date }
			].to_json

            get "helpdesk/requests/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
        end

        def test_download_requests_csv_filter_by_role
			filter = [
				{ property: 'role', value: 'Dealer' }
            ].to_json

            get "helpdesk/requests/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
		end

        def test_download_requests_csv_filter_by_state_and_city
			filter = [
				{ property: 'state', value: @state_id },
				{ property: 'city', value: @city_id }
			].to_json

            get "helpdesk/requests/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
		end

	end

	context 'helpdesk - update request dealer registration' do
		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

        def test_helpdesk_request_update_valid_dealer_registration

			put "/helpdesk/requests/#{$help_dealer_request.id}", {
				token: @token,
				participant_type:'dealer',
				name: 'XXX',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				parent_id: $cso.id
			}.to_json

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context 'helpdesk - update request rsa registration' do
		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			put "/helpdesk/requests/#{$help_dealer_request.id}", {
				token: @token,
				participant_type:'rsa',
				name: 'XXX',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				parent_id: $cso.id
			}.to_json

			delete "/helpdesk/requests/#{$help_dealer_request.id}", {token: @token}.to_json
			data = indifferent_data(JSON.parse(last_response.body))

			@registered_dealer = Participant.where(mobile: $help_dealer_request.mobile).first
		end

		def test_helpdesk_request_update_rsa_registration_under_invalid_dealer

			put "/helpdesk/requests/#{$help_rsa_request.id}", {
				token: @token,
				participant_type:'RSA',
				name: 'yyy',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				firmname: 'qwerty',
				tier: 'silver',
				code: 'qwerty103',
				parent_id:'1111111111'
			}.to_json

			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
		end

		def test_helpdesk_request_update_rsa_registration_under_valid_dealer
			put "/helpdesk/requests/#{$help_rsa_request.id}", {
				token: @token,
				participant_type:'rsa',
				name: 'yyy',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				firmname: 'qwerty',
				tier: 'silver',
				code: 'qwerty103',
				parent_id: @registered_dealer.id

			}.to_json

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context 'helpdesk - delete request' do
		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get "/helpdesk/requests",{
				token: @token,
				page: 1,
				start: 0,
				limit: 25
			}

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			@req = data[:values].first

			put "/helpdesk/requests/#{$help_dealer_request.id}", {
				token: @token,
				participant_type:'dealer',
				name: 'XXX',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				parent_id: $cso.id
			}.to_json

			delete "/helpdesk/requests/#{$help_dealer_request.id}", {token: @token}.to_json
			data = indifferent_data(JSON.parse(last_response.body))

			@registered_dealer = Participant.where(mobile: $help_dealer_request.mobile).first

			put "/helpdesk/requests/#{$help_rsa_request.id}", {
				token: @token,
				participant_type:'rsa',
				name: 'yyy',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				firmname: 'qwerty',
				tier: 'silver',
				code: 'qwerty133',
				parent_id: @registered_dealer.id
			}.to_json

		end

		def test_heldesk_request_delete_valid_permanent
			delete "/helpdesk/requests/#{$help_rsa_request.id}", {token: @token, permanent: true}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

	end

	context 'helpdesk - register dealer - valid' do
		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			put "/helpdesk/requests/#{$help_dealer_request.id}", {
				token: @token,
				participant_type:'dealer',
				name: 'XXX',
				address1: 'AAA',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				firmname: 'qwerty',
				tier: 'silver',
				code: 'qwerty113',
				parent_id: $cso.id ,
			}.to_json
		end

		def test_register_helpdesk_request_dealer_valid
			delete "/helpdesk/requests/#{$help_dealer_request.id}", {token: @token}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

		def test_delete_helpdesk_request_dealer
			delete "/helpdesk/requests/#{$help_dealer_request.id}", {token: @token, permanent: true}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

	end

	context 'helpdesk - register rsa - valid' do
		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			put "/helpdesk/requests/#{$help_rsa_request.id}", {
				token: @token,
				participant_type:'rsa',
				name: 'rsa new',
				address1: 'rsa',
				city_id: $bangalore.id,
				state_id: $bangalore.state.id,
				pincode: '123213',
				firmname: 'qwerty',
				tier: 'gold',
				code: 'qwerty123',
				parent_id: $dl.id,
			}.to_json
		end

		def test_register_helpdesk_request_rsa_valid
			delete "/helpdesk/requests/#{$help_rsa_request.id}", {token: @token}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

		def test_delete_helpdesk_request
			delete "/helpdesk/requests/#{$help_rsa_request.id}", {token: @token, permanent: true}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

	end

	context 'helpdesk - search for supervisor' do
		def setup
			create_helpdesk_user
			create_helpdesk_request
			create_participants_and_permissions

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def tests_search_supervisor_for_rsa
			filter = [
				{ property: 'mobile', value: $dl.mobile },
				{ property: 'role', value: 'dealer' }
			].to_json

			get "/helpdesk/requests/supervisor",{
				token: @token,
				mobile: $dl.mobile,
				role: 'dl'
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end
	end


end