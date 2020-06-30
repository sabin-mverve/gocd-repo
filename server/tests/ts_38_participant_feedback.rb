# require_relative '0 helper/helper'

# class Testclass < SequelTestCase
# 	include Rack::Test::Methods

# 	def app
#         App.app
# 	end

# 	context "Send Feedback" do
# 		def setup
# 			create_helpdesk_user
#             create_participants_and_permissions

# 			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @token = data[:values][:token]

#             post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
# 			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @ptoken = data[:values][:token]
# 		end

# 		def test_send_feedback_customer_valid
#             post "/participant/feedback", {customer_mobile: '919191919191',token:@ptoken}.to_json

# 			assert_equal 200, last_response.status
# 			data = indifferent_data(JSON.parse(last_response.body))
#             assert_not_nil data
#             assert_equal true, data[:success]
#         end
#     end

#     context "Send Feedback same customer within 30 days" do
# 		def setup
# 			create_helpdesk_user
#             create_participants_and_permissions

# 			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @token = data[:values][:token]

#             post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
# 			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @ptoken = data[:values][:token]

#             post "/participant/feedback", {customer_mobile: '919191919191',token:@ptoken}.to_json
#             data = indifferent_data(JSON.parse(last_response.body))
#             @customer_mobile = data[:values][:customer_mobile]

# 		end

#         def test_send_feedback_within_thirty_days_invalid
#             post "/participant/feedback", {customer_mobile: @customer_mobile,token:@ptoken}.to_json

# 			assert_equal 500, last_response.status
# 			data = indifferent_data(JSON.parse(last_response.body))
# 			assert_not_nil data
# 			assert_equal false, data[:success]
# 			assert_not_nil data[:error]
#         end
# 	end

# 	context 'feedback - webhook - sms yes and tyes and tno and no by customer' do
# 		def setup
# 			@secret ='lnd848dd10327'

# 			create_participants_and_permissions
# 			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
# 			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @ptoken = data[:values][:token]

#             post "/participant/feedback", {customer_mobile: '911010101010',token:@ptoken}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))

# 		end

# 		def test_webhook_sms_tyes_valid
# 			obj = {
# 				secret: @secret,
# 				sender: '911122334455',
# 				keyword: 'TYES',
# 				# received_on: '2020-14-22_11:00:00',
# 				received_on: '2020-05-14 14:40:05',
# 				message: 'blah',
# 				operator: 'Airtel',
# 				circle: 'Karnataka'
# 			}
# 			get "/participant/sms", obj
# 			assert_equal 200, last_response.status
# 			assert_equal 'success', last_response.body
# 		end

# 		def test_webhook_sms_yes_valid
# 			obj = {
# 				secret: @secret,
# 				sender: '911010101010',
# 				keyword: 'YES',
# 				# received_on: '2020-14-22_11:00:00',
# 				received_on: '2020-04-22 14:40:05',
# 				message: 'blah',
# 				operator: 'Airtel',
# 				circle: 'Karnataka'
# 			}
# 			get "/participant/sms", obj
# 			assert_equal 200, last_response.status
# 			assert_equal 'success', last_response.body
# 		end

# 		def test_webhook_sms_tno_valid
# 			obj = {
# 				secret: @secret,
# 				sender: '911010101010',
# 				keyword: 'TNO',
# 				# received_on: '2020-14-22_11:00:00',
# 				received_on: '2020-04-22 14:40:05',
# 				message: 'blah',
# 				operator: 'Airtel',
# 				circle: 'Karnataka'
# 			}
# 			get "/participant/sms", obj
# 			assert_equal 200, last_response.status
# 			assert_equal 'success', last_response.body
# 		end

# 		def test_webhook_sms_no_valid
# 			obj = {
# 				secret: @secret,
# 				sender: '911010101010',
# 				keyword: 'NO',
# 				# received_on: '2020-14-22_11:00:00',
# 				received_on: '2020-04-22 14:40:05',
# 				message: 'blah',
# 				operator: 'Airtel',
# 				circle: 'Karnataka'
# 			}
# 			get "/participant/sms", obj
# 			assert_equal 200, last_response.status
# 			assert_equal 'success', last_response.body
# 		end
# 	end

# 	context 'feedback - webhook - feedback by unknown customer' do
# 		def setup
# 			@secret ='lnd848dd10327'

# 			create_participants_and_permissions
# 			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
# 			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @ptoken = data[:values][:token]

#             post "/participant/feedback", {customer_mobile: '911010101010',token:@ptoken}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))

# 		end

# 		def test_webhook_sms_by_unknown
# 			obj = {
# 				secret: @secret,
# 				sender: '123123123123',
# 				keyword: 'NO',
# 				# received_on: '2020-14-22_11:00:00',
# 				received_on: '2020-04-22 14:40:05',
# 				message: 'blah',
# 				operator: 'Airtel',
# 				circle: 'Karnataka'
# 			}
# 			get "/participant/sms", obj
# 			assert_equal 200, last_response.status
# 			assert_equal 'failure', last_response.body
# 		end
# 	end

# 	context 'feedback - webhook - feedback by invalid format' do
# 		def setup
# 			@secret ='lnd848dd10327'

# 			create_participants_and_permissions
# 			post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
# 			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))
#             @ptoken = data[:values][:token]

#             post "/participant/feedback", {customer_mobile: '911010101010',token:@ptoken}.to_json
# 			data = indifferent_data(JSON.parse(last_response.body))

# 		end

# 		def test_webhook_sms_by_customer_with_invalid_format
# 			obj = {
# 				secret: @secret,
# 				sender: '911010101010',
# 				keyword: 'ABC',
# 				# received_on: '2020-14-22_11:00:00',
# 				received_on: '2020-04-22 14:40:05',
# 				message: 'blah',
# 				operator: 'Airtel',
# 				circle: 'Karnataka'
# 			}
# 			get "/participant/sms", obj
# 			assert_equal 200, last_response.status
# 			assert_equal 'failure', last_response.body
# 		end
# 	end
# end
