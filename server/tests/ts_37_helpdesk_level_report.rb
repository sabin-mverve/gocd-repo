require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
        App.app
	end

	context "Get level quiz report" do
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

			get "/participant/levels/titles/#{@record[:level_title_id]}/questions", {token:@ptoken}
			data = indifferent_data(JSON.parse(last_response.body))
			@question_1 = data[:values][0]
			@question_2 = data[:values][1]


			rec = [{
                question_id: @question_1[:id],
				answer: 1,
				count: @question_1[:count]
            },{
                question_id: @question_2[:id],
				answer: 3,
				count: @question_2[:count]
			}]
            post "/participant/levels/titles/#{@record[:level_title_id]}", {
                rec: rec,
                token:@ptoken
            }.to_json
		end

		def test_get_levels_report
			get "/helpdesk/reports/levels", {page: 1, start: 0, limit: 25,token: @token}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert_equal true, data[:success]
		end

		def test_download_levelsreport_csv
            get '/helpdesk/reports/levels/download/levelsreport-2019-10-02_04-57-14.csv', {token: @token}
            assert_equal 200, last_response.status

		end

		def test_download_levelsreport_csv_filter_query_mobile
			filter = [
				{ property: 'query', value: '12345' }
			].to_json

			get '/helpdesk/reports/levels/download/levelsreport-2020-10-02_04-57-14.csv', {token: @token, filter: filter}
			assert_equal 200, last_response.status
		end

        # def test_download_levelsreport_csv_filter_daterange
		# 	date = Time.now.strftime("%Y-%m-%d")
		# 	filter = [
		# 		{ property: 'from', value: date },
		# 		{ property: 'to', value: date }
		# 	].to_json

		# 	get '/helpdesk/reports/levels/download/levelsreport-2018-10-02_04-57-14.csv', {token: @token, filter: filter}
		# 	assert_equal 200, last_response.status
		# end


	end
end