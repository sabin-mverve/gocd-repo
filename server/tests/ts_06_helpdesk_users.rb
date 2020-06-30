require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'helpdesk - get users list' do
		def setup
			create_helpdesk_user
			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get '/helpdesk/states', {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			state = data[:values].find { |r| r[:name] == 'Karnataka' }
			@state_id = state[:id]

			get "/helpdesk/cities", {token: @token, state_id: @state_id}
			data = indifferent_data(JSON.parse(last_response.body))
			city = data[:values].find { |r| r[:city_name] == 'Bangalore' }
			@city_id = city[:city_id]
		end

		def test_get_users
			get '/helpdesk/users', {page: 1, start: 0, limit: 25, token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
            assert_true data[:values].is_a? Array
			if data[:values].length > 0
				sample_user = data[:values][0]
				assert_not_nil sample_user[:created_at]
				assert_not_nil sample_user[:name]
				assert_not_nil sample_user[:mobile]
				assert_not_nil sample_user[:participant_type]
				assert_not_nil sample_user[:active]
				assert_not_nil sample_user[:parent_id]

				# ---------- ADDRESS ----------------
				assert_not_nil sample_user[:address1]
				assert_not_nil sample_user[:city_id]
				assert_not_nil sample_user[:city_name]
				assert_not_nil sample_user[:state_id]
				assert_not_nil sample_user[:state_name]
				assert_not_nil sample_user[:pincode]

				# ---------- DETAILS ----------------
			end

		end

		def test_filter_by_state
			filter = [
				{ property: 'state', value: @state_id }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
            first = data[:values].first
			assert_equal @state_id, first[:state_id]
		end

		def test_filter_by_state_and_city
			filter = [
				{ property: 'state', value: @state_id },
				{ property: 'city', value: @city_id }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
			first = data[:values].first
			assert_equal @state_id, first[:state_id]
			assert_equal @city_id, first[:city_id]
		end

		def test_filter_by_role
			filter = [
				{ property: 'role', value: 'Dealer' }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_search_users_by_mobile
			filter = [
				{ property: 'query', value: '1234' }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_search_users_by_name
			filter = [
				{ property: 'query', value: 'P 1' }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_filter_by_date_range
			filter = [
				{ property: 'from', value: '2018-08-30' },
				{ property: 'to', value: '2018-09-01' }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_filter_by_role_and_date_range
			filter = [
				{ property: 'role', value: 'Carpenter' },
				{ property: 'from', value: '2018-08-30' },
				{ property: 'to', value: '2018-09-01' }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_sort_and_filter_by_date_range
			sort = {
				property: 'created_at', direction: 'DESC'
			}
			filter = [
				{ property: 'from', value: '2018-08-30' },
				{ property: 'to', value: '2018-09-01' }
			].to_json
			get '/helpdesk/users', {token: @token, page: 1, start: 0, limit: 25, filter: filter, sorter: sort}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_download_users_csv
            get "helpdesk/users/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10}
			assert_equal 200, last_response.status
		end

        def test_download_users_csv_filter_by_date
			date = Time.now.strftime("%Y-%m-%d")
			filter = [
				{ property: 'fromdate', value: date },
				{ property: 'todate', value: date }
			].to_json

            get "helpdesk/users/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
        end

        def test_download_users_csv_filter_by_role
			filter = [
				{ property: 'role', value: 'Dealer' }
            ].to_json

            get "helpdesk/users/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
		end

        def test_download_users_csv_filter_by_state_and_city
			filter = [
				{ property: 'state', value: @state_id },
				{ property: 'city', value: @city_id }
			].to_json

            get "helpdesk/users/download/2019-04-10_16-43-31.csv", {token: @token, page: 1, start: 0, limit: 10, filter: filter}
            assert_equal 200, last_response.status
		end
	end

	context 'helpdesk - update users' do
		def setup
			create_helpdesk_user
			create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get '/helpdesk/users', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@user = data[:values][0]
		end

		def test_update_user_identifiers
			put "/helpdesk/users/#{@user[:id]}", {
				token: @token,
				name: 'ZZZ',
                email: 'asf@email.com',
                store_name: 'wiehd'
				# otp: @otp
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal 'ZZZ', data[:values][:name]
			assert_equal 'asf@email.com', data[:values][:email]
		end

		def test_update_user_details
			put "/helpdesk/users/#{@user[:id]}", {
				token: @token,
				dob: '1994/01/23',
                doa: '1994/01/23',
                store_name: 'wqhk'
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

		def test_update_user_address
			put "/helpdesk/users/#{@user[:id]}", {
				token: @token,
				address1: 'asdfadfasdf',
				address2: 'asdfadfasdf',
                pincode: 'asdfadfasdf',
                store_name: 'iuhefdkw'
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal 'asdfadfasdf', data[:values][:address1]
			assert_equal 'asdfadfasdf', data[:values][:address2]
			assert_equal 'asdfadfasdf', data[:values][:pincode]
		end

		def test_update_parent_id
			put "/helpdesk/users/#{@user[:id]}", {
				token: @token,
                parent_id: $cso.id,
                store_name: 'hfdsa'
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal  $cso.id, data[:values][:parent_id]
		end
	end

	context 'helpdesk - update user deactivate user' do
		def setup
			create_helpdesk_user
			create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get '/helpdesk/users', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@user = data[:values][0]
		end

		def test_deactivate_user
			put "/helpdesk/users/#{@user[:id]}", {
				token: @token,
				active: false
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]

			get '/helpdesk/users', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@user = data[:values][0]
			assert_equal false, @user[:active]
		end
	end

end
