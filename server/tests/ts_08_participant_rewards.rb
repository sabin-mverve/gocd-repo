require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	# context 'rewards catalog - categories - inactive participant' do
	# 	def setup
	# 		create_helpdesk_user
	# 		create_participants_and_permissions
	# 		create_rewards

	# 		post "/helpdesk/login", {email: $hduser_email, password:  $hduser_password}.to_json
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		@hd_token = data[:values][:token]

	# 		post "/participant/mobile", {mobile: $mobile, player_id: $player_id}.to_json
	# 		post "/participant/login", {mobile: $mobile, otp: $otp, player_id: $player_id}.to_json
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		@token = data[:values][:token]

	# 		put "/helpdesk/users/#{$participant_id}", {token: @hd_token, active: false}
	# 	end

	# 	def test_categories_inactive_participant
	# 		get "/participant/categories", {token: @token}
	# 		assert_equal 500, last_response.status
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		assert_not_nil data
	# 		assert_equal false, data[:success]
	# 		assert_not_nil data[:error]
	# 	end
	# end

	context 'rewards catalog - categories' do
		def setup
			create_participants_and_permissions
			create_rewards

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_get_rewards_categories_invalid_token
			get "/participant/catalogue/categories", {token: '12131'}
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_get_rewards_categories_valid_token
			get "/participant/catalogue/categories", {token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end
	end

	# context 'rewards catalog - sub-categories - inactive participant' do
	# 	def setup
	# 		create_helpdesk_user
	# 		create_participants_and_permissions
	# 		create_rewards

	# 		post "/helpdesk/login", {email: $hduser_email, password:  $hduser_password}.to_json
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		@hd_token = data[:values][:token]

	# 		post "/participant/mobile", {mobile: $mobile, player_id: $player_id}.to_json
	# 		post "/participant/login", {mobile: $mobile, otp: $otp, player_id: $player_id}.to_json
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		@token = data[:values][:token]

	# 		# this cateogry exists from the seeder
	# 		get "/participant/categories", {token: @token}
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		@category_id = data[:values][0][:id]

	# 		put "/helpdesk/users/#{$participant_id}", {token: @hd_token, active: false}
	# 	end

	# 	def test_get_rewards_sub_categories_valid_category_id_inactive_participant
	# 		get "/participant/categories/#@category_id/subcategories", {token: @token}
	# 		assert_equal 500, last_response.status
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		assert_not_nil data
	# 		assert_equal false, data[:success]
	# 		assert_not_nil data[:error]
	# 	end

	# 	def test_get_rewards_valid_category_id_inactive_participant
	# 		get "/participant/categories/#@category_id/rewards", {token: @token, page: 1, start: 0, limit: 2}
	# 		assert_equal 500, last_response.status
	# 		data = indifferent_data(JSON.parse(last_response.body))
	# 		assert_not_nil data
	# 		assert_equal false, data[:success]
	# 		assert_not_nil data[:error]
	# 	end

	# end

	context 'rewards catalog - sub-categories' do
		def setup
			create_participants_and_permissions
			create_rewards

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			# this cateogry exists from the seeder
			get "/participant/catalogue/categories", {token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			@category_id = data[:values][0][:id]
		end

		def test_get_rewards_sub_categories_invalid_category_id
			get "/participant/catalogue/categories/9999/subcategories", {token: @token}
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

		def test_get_rewards_sub_categories_valid_category_id
			get "/participant/catalogue/categories/#{@category_id}/subcategories", {token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))

			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end

		def test_get_rewards_valid_category_id
			get "/participant/catalogue/categories/#{@category_id}/rewards", {token: @token, page: 1, start: 0, limit: 2}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))

			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
		end

		def test_get_rewards_with_filters_and_pagination
			filter = [
				{ property: 'sub_category_id', value: 1} ,
				{ property: 'min_points', value: 100 } ,
				{ property: 'max_points', value: 500 }
			].to_json
			sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json
			get "/participant/catalogue/categories/#{@category_id}/rewards", {token: @token, page: 1, start: 0, limit: 25, filter: filter, sort: sorter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_equal Array, data[:values].class
			assert_not_nil data[:total]
		end

		def test_get_participant_rewards_list_search_by_name
			filter = [
				{ property: 'query', value: 'omega' }
			].to_json
			get "/participant/catalogue/categories/#{@category_id}/rewards", {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))

			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
		end


	end
end