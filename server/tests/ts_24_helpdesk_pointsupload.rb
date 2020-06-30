require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
    end

    context "Helpdesk Points Upload - verify" do

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

        def test_uploadpoints_verify

            recs =[{
                mobile: $mobile3,
                points: "2000",
                description: "abcdefghijklmnop"
            }]
            post "/helpdesk/uploadpoints/verify",{
                recs:recs,
                token: @token
            }.to_json

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal true, data[:success]
            assert_not_nil data[:values]
        end

        def test_uploadpoints_verify_invalid_number

            recs =[{
                mobile: '11111',
                points: "2000",
                description: "abcdefghijklmnop"
            }]
            post "/helpdesk/uploadpoints/verify",{
                recs:recs,
                token: @token
            }.to_json

            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:values]
        end

        def test_uploadpoints_verify_insufficient_points
            recs = [{
                mobile: $mobile3,
                points: "-1000",
                description: "qwerty",
                category: "award"
            }]
            post "/helpdesk/uploadpoints/verify",{
                recs:recs,
                token: @token
            }.to_json

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
            assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:values]
        end
    end

    context "Helpdesk Points Upload - Submit" do

        def setup

            create_helpdesk_user
            create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            recs =[{
                mobile: $mobile3,
                points: "2000",
                description: "abcdefghijklmnop"
            }]
            post "/helpdesk/uploadpoints/verify",{
                recs:recs,
                token: @token
            }.to_json

            post "/helpdesk/uploadpoints/submit",{
                recs:recs,
                token: @token
            }.to_json

        end

        def test_uploadpoints_submit
            recs =[{
                mobile: $mobile3,
                points: "100",
                description: "abcdefghijklmnop",
            },{
                mobile: $mobile3,
                points: "100",
                description: "abcdefghijklmnop",
            },{
                mobile: $mobile3,
                points: "10",
                description: "abcdefghijklmnop",
            }]
            post "/helpdesk/uploadpoints/submit",{
                recs:recs,
                token: @token
            }.to_json

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal true, data[:success]
            assert_not_nil data[:values]
        end

        def test_uploadpoints_deduct_points
            recs = [{
                mobile: $mobile3,
                points: "-100",
                description: "qwerty",
                category: "award"
            }]
            post "/helpdesk/uploadpoints/submit",{
                recs:recs,
                token: @token
            }.to_json

            assert_equal 200, last_response.status
            data = indifferent_data(JSON.parse(last_response.body))
			assert_equal true, data[:success]
            assert_not_nil data[:values]
        end
    end
end