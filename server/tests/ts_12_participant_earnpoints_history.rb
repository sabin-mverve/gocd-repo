require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant - get earnpoints history' do
		def setup
			create_participants_and_permissions
			create_rewards
			create_helpdesk_user

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: "111111", player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_participant_all_earnpoints_history
			get "/participant/earnhistory/claim", {token: @token, page: 1, start: 0, limit: 10}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
			assert_equal Array, data[:values].class
		end


		def test_participant_earnpoints_history_with_filter
			today = Date.today
			yesterday = today - 1

			from = yesterday.strftime("%Y-%m-%d")
			to = today.strftime("%Y-%m-%d")

			filter = [ { property: 'from', value: yesterday } , { property: 'to', value: today }].to_json

			sorter = [
				{ property: 'points', direction: 'DESC' }
			].to_json

			get "/participant/earnhistory/claim", {token: @token, page: 1, start: 0, limit: 10, filter: filter, sort: sorter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:total]
			assert_equal Array, data[:values].class
		end

	end

end