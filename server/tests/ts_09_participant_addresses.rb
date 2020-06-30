require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
	end

	context 'participant -  add address' do
		def setup
			create_participants_and_permissions

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_participant_add_new_address

			post "/participant/address", {
				token: @token,
				name: "test",
				mobile: "1234567891",
				district: "district",
				address1: "test address 1",
				address2: "test address 2",
				address3: "address3",
				city_id: 1,
				state_id: 1,
				city_name: "Hyderabad",
				state_name: "Telangana",
				pincode: "123456"
			}.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal true, data[:success]
			assert_not_nil data[:values][:name]
			assert_not_nil data[:values][:mobile]
			assert_not_nil data[:values][:address1]
			assert_not_nil data[:values][:address2]
			assert_not_nil data[:values][:address3]
			assert_not_nil data[:values][:district]
			assert_not_nil data[:values][:pincode]
		end

		def test_participant_get_address

			get "/participant/address", {token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal true, data[:success]
		end
	end

	context 'participant- remove address' do

		def setup
			create_participants_and_permissions

			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get "/participant/address", {token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal true, data[:success]
			@addr_id =  data[:values][0]
		end


		def test_participant_delete_address_minimumcheck

			delete "/participant/address/#{@addr_id[:id]}", {token: @token}
			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_equal false, data[:success]
		end
	end

end