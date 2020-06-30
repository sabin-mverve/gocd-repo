require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context "Add Questions" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}

			get "/helpdesk/lne/topics", {page: 1, start: 0, limit: 25,token:@token}
			data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]


		end

        def test_add_question_valid

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

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Get Questions" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'


			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
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

        def test_get_question_valid
			get "/helpdesk/lne/topics/#{@record[:id]}/questions", {token:@token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Update Questions" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'


			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
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

			get "/helpdesk/lne/topics/#{@record[:id]}/questions", {token:@token}
			data = indifferent_data(JSON.parse(last_response.body))

			@que = data[:values].first
		end

        def test_update_question_valid
			put "/helpdesk/lne/topics/#{@record[:id]}/questions/#{@que[:id]}", {
				question: "What is the capital of India?",
				correct: 0,
				answers: [{
                    option_0: 'Delhi',
			    	option_1: 'Kolkata',
			    	option_2: 'Mumbai',
			    	option_3: 'Maharastra',
                }],
				token:@token
				}.to_json

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Delete Questions" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'


			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
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

			get "/helpdesk/lne/topics/#{@record[:id]}/questions", {token:@token}
			data = indifferent_data(JSON.parse(last_response.body))

			@que = data[:values].first
		end

        def test_delete_question_valid
			delete "/helpdesk/lne/topics/#{@record[:id]}/questions/#{@que[:id]}", {token:@token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Publish Topic" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'


			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
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

        def test_publish_valid
			post "/helpdesk/lne/topics/#{@record[:id]}/publish", {
			# put "/helpdesk/lne/topics/#{@record[:id]}", {
				publish: true,
				token:@token
			}.to_json

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end
	end

	context "Invalids Topic" do
		def setup
			create_helpdesk_user

			post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]

            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.pdf'))
            mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'


			@today = Date.today
			post "/helpdesk/lne/topics", {
				month: @today.month,
				year: @today.year,
				topic:'Electronics',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				attachment_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				token:@token
			}
			post "/helpdesk/lne/topics", {
				month: @today.next_month.month,
				year: @today.next_year.year,
				topic:'Mattress',
				attachment_01: Rack::Test::UploadedFile.new(filepath, mime_type),
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

			post "/helpdesk/lne/topics/#{@record[:id]}/publish", {
				# put "/helpdesk/lne/topics/#{@record[:id]}", {
					publish: true,
					token:@token
				}.to_json
		end

        def test_update_topic_invalid

			put "/helpdesk/lne/topics/#{@record[:id]}", {
				month: 10,
				topic:'Mattress',
				token:@token
			}

			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end

        def test_add_questions_invalid

			rec = [{
                question: 'whats your name?',
				correct: 1,
                answers: [{
                    option_0: 'abc'
                }]
			},{
				question: 'whats your name?',
				correct: 3,
                answers: [{
                    option_0: ''
                }]
			}]

			post "/helpdesk/lne/topics/#{@record[:id]}/questions", {
				rec: rec,
				token:@token
			}.to_json


			assert_equal 500, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal false, data[:success]
			assert_not_nil data[:error]
		end
	end
end