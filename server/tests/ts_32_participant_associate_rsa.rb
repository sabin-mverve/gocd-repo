require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant-associate rsa' do
		def setup
			create_participants_and_permissions
			create_rewards
			create_helpdesk_user
			create_product_and_coupons


			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile2, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile2, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

		end

		def test_get_associate_rsa
			get '/participant/dealers/associate_rsa', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_not_nil data
			assert_equal true, data[:success]
		end


		def test_search_rsa_by_mobile
			filter = [
				{ property: 'query', value: '1234' }
			].to_json
			get '/participant/dealers/associate_rsa', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_search_rsa_by_name
			filter = [
				{ property: 'query', value: 'rsa 1' }
			].to_json
			get '/participant/dealers/associate_rsa', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_true data[:values].is_a? Array
		end
	end

	context 'participant-dealer-total pool points' do

			def setup
			create_participants_and_permissions
			create_rewards
			create_helpdesk_user
			create_product_and_coupons


			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile2, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile2, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

		end

		def test_get_total_pool_points
			get '/participant/dealers/poolpoints', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_not_nil data
			assert_equal true, data[:success]
		end

		def test_get_total_pool_points_earnhistory
			get "/participant/dealers/poolpoints/#{$participant_id}/earnhistory", {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_not_nil data
			assert_equal true, data[:success]
		end


	end
	context 'participant-dealer-quiz-status' do

		def setup
			create_participants_and_permissions
			create_rewards
			create_helpdesk_user
			create_product_and_coupons


			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@hd_token = data[:values][:token]

			post "/participant/mobile", {mobile: $mobile2, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile2, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end


		def test_get_dealer_quiz_status
			get '/participant/dealers/quizstatus', {page: 1, start: 0, limit: 25, token: @token}
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal 200, last_response.status
			assert_not_nil data
			assert_equal true, data[:success]
		end

	end

end