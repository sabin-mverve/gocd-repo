require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context "Submit Material counter" do
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

			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',
				token:@token
			}

			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',
				token:@token
			}


			get "/helpdesk/levels/titles", { level:1 , page: 1, start: 0, limit: 25,token:@token}
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

			post "/helpdesk/levels/titles/#{@record[:level_title_id]}/questions", {
				rec: rec,
				token:@token
			}.to_json

			post "/helpdesk/levels/titles/#{@record[:level_title_id]}/publish", {
					publish: true,
					token:@token
				}.to_json

			get "/participant/levels/titles", {page: 1, start: 0, limit: 25,token:@ptoken}
			data = indifferent_data(JSON.parse(last_response.body))
			@material_id =  data[:values][0][:materials][0][:id]
			@v_material_id =  data[:values][0][:materials][2][:id]

			get "/participant/levels/titles/#{@record[:level_title_id]}/questions", {token:@ptoken}
			data = indifferent_data(JSON.parse(last_response.body))
			@question_1 = data[:values][0]
			@question_2 = data[:values][1]
		end

		def test_get_level_submit_material_counter

            post "/participant/levels/titles/#{@record[:level_title_id]}/materials/#{@material_id}", {
				# user_id: 3,
				material_id: @material_id,
				material_type: 'pdf',
                token:@ptoken
            }.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
		end

		def test_get_level_submit_material_counter_video

            post "/participant/levels/titles/#{@record[:level_title_id]}/materials/#{@material_id}", {
				# user_id: 3,
				material_id: @v_material_id,
				material_type: 'video',
				resume_min:3.4,
                token:@ptoken
            }.to_json
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
            assert_equal true, data[:success]
        end
	end

	context "get-titles after submitting material counter" do
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

			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',
				token:@token
			}

			post "/helpdesk/levels/titles", {
				level: 1,
				title: 'title',
				description:'Electronics',
				published: false,
				attempted: false,
				material_01: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_02: Rack::Test::UploadedFile.new(filepath, mime_type),
				material_03: '12121212',
				token:@token
			}


			get "/helpdesk/levels/titles", { level:1 , page: 1, start: 0, limit: 25,token:@token}
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

			post "/helpdesk/levels/titles/#{@record[:level_title_id]}/questions", {
				rec: rec,
				token:@token
			}.to_json

			post "/helpdesk/levels/titles/#{@record[:level_title_id]}/publish", {
					publish: true,
					token:@token
				}.to_json

			get "/participant/levels/titles", {page: 1, start: 0, limit: 25,token:@ptoken}
			data = indifferent_data(JSON.parse(last_response.body))
			@material_id =  data[:values][0][:materials][0][:id]
			@v_material_id =  data[:values][0][:materials][2][:id]

			get "/participant/levels/titles/#{@record[:level_title_id]}/questions", {token:@ptoken}
			data = indifferent_data(JSON.parse(last_response.body))
			@question_1 = data[:values][0]
			@question_2 = data[:values][1]

			post "/participant/levels/titles/#{@record[:level_title_id]}/materials/#{@material_id}", {
				# user_id: 3,
				material_id: @material_id,
				material_type: 'pdf',
                token:@ptoken
			}.to_json

			post "/participant/levels/titles/#{@record[:level_title_id]}/materials/#{@material_id}", {
				# user_id: 3,
				material_id: @v_material_id,
				material_type: 'video',
				resume_min:3.4,
                token:@ptoken
            }.to_json
		end

		def test_get_all_levels_titles_material_counter
			get "/participant/levels/titles", {page: 1, start: 0, limit: 25,token:@ptoken}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
			assert_not_nil data[:values][0][:title]
			assert_not_nil data[:values][0][:description]
			assert_not_nil data[:values][0][:level]
		end
	end
end