require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context "Get Topic" do
		def setup
			create_helpdesk_user
            create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@ptoken = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            today = Date.today
			post "/helpdesk/lne/topics", {
				month: today.month,
				year: today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: today.month,
				year: today.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: 03,
				year: 2018,
				topic:'Automobile',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}

			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]

			rec = [{
                question: 'whats your name?',
				correct: 1,
                answers: [{
                    option_0: 'abc',
			    	option_1: 'efg',
                }]
			},{
				question: 'whats your name?',
				correct: 3,
                answers: [{
                    option_0: 'abc',
			    	option_1: 'efg',
			    	option_2: 'pqr',
			    	option_3: 'xyz',
                }]
			}]

			post "/helpdesk/lne/topics/#{@record[:id]}/questions", {
				rec: rec,
				token:@token
			}.to_json

            rec = [{
                question_id: 1,
                answer: 1
            },{
                question_id: 2,
                answer: 3
            }]
            post "/participant/lne/topics/#{@record[:id]}", {
                rec: rec,
                token:@ptoken
            }.to_json

            post "/helpdesk/lne/topics/#{@record[:id]}/publish", {
                publish: true,
                token:@token
            }.to_json
        end

        def test_get_till_date_valid_topic
			get "/participant/lne/topics", {page: 1, start: 0, limit: 25,token:@ptoken}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
			assert_not_nil data[:values][0][:month]
			assert_not_nil data[:values][0][:year]
			assert_not_nil data[:values][0][:topic]
		end

    end

    context "Get Questions" do
		def setup
			create_helpdesk_user
            create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@ptoken = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
			current_year = Time.now.year
			post "/helpdesk/lne/topics", {
				month: 03,
				year: current_year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: 04,
				year: current_year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: 03,
				year: current_year,
				topic:'Automobile',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			
			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]
			rec = [{
                question: 'whats your name?',
				correct: 1,
                answers: [{
                    option_0: 'abc',
			    	option_1: 'efg',
                }]
			},{
				question: 'whats your name?',
				correct: 3,
                answers: [{
                    option_0: 'abc',
			    	option_1: 'efg',
			    	option_2: 'pqr',
			    	option_3: 'xyz',
                }]
			}]

			post "/helpdesk/lne/topics/#{@record[:id]}/questions", {
				rec: rec,
				token:@token
			}.to_json

		end

        def test_get_question_valid_participant
			get "/participant/lne/topics/#{@record[:id]}/questions", {token:@ptoken}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
		end
    end

    context "Submit Quiz Answers" do
		def setup
			create_helpdesk_user
            create_participants_and_permissions

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            post "/participant/mobile", {mobile: $mobile3, player_id: $player_id}.to_json
			post "/participant/login", {mobile: $mobile3, otp: $otp, player_id: $player_id}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@ptoken = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
			current_year = Time.now.year
			post "/helpdesk/lne/topics", {
				month: 03,
				year: current_year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: 04,
				year: current_year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: 03,
				year: current_year,
				topic:'Automobile',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}

			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]

			rec = [{
                question: 'whats your name?',
				correct: 1,
                answers: [{
                    option_0: 'abc',
			    	option_1: 'efg',
                }]
			},{
				question: 'whats your name?',
				correct: 3,
                answers: [{
                    option_0: 'abc',
			    	option_1: 'efg',
			    	option_2: 'pqr',
			    	option_3: 'xyz',
                }]
			}]

			post "/helpdesk/lne/topics/#{@record[:id]}/questions", {
				rec: rec,
				token:@token
			}.to_json

			get "/participant/lne/topics/#{@record[:id]}/questions", {token:@ptoken}
			data = indifferent_data(JSON.parse(last_response.body))
			@question_1 = data[:values][0]
			@question_2 = data[:values][1]
		end

        def test_get_submit_valid

            rec = [{
                question_id: @question_1[:id],
				answer: 1,
				count: @question_1[:count]
            },{
                question_id: @question_2[:id],
				answer: 3,
				count: @question_2[:count]
			}]
            post "/participant/lne/topics/#{@record[:id]}", {
                rec: rec,
                token:@ptoken
            }.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
        end

        def test_get_submit_invalid
            rec = [{
				question_id: @question_1[:id],
				answer: 2,
				count: @question_1[:count]
            },{

                question_id: @question_2[:id],
				answer: 3,
				count: @question_2[:count]
            }]
            post "/participant/lne/topics/#{@record[:id]}", {
                rec: rec,
                token:@ptoken
            }.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
		end
    end


end