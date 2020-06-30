require_relative '0 helper/helper'

class Testclass < SequelTestCase
	include Rack::Test::Methods

	def app
		App.app
    end

    context 'helpdesk - get list of all rewards' do
        def setup
			create_helpdesk_user

            post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

            create_rewards
			@category = Category.first
			@subcategory = @category.subcategories.first
        end

        def test_get_helpdesk_rewards_list
			get "/helpdesk/catalogue/rewards", {page: 1, start: 0, limit: 25, token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]

            assert_not_nil data[:total]
			assert_true data[:values].is_a? Array
        end

        def test_get_helpdesk_rewards_list_filter_by_brand
            filter = [
				{ property: 'brand', value: 'prestige' }
            ].to_json
            get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
			first = data[:values].first
			assert_equal 'prestige', first[:brand].downcase
        end

        def test_get_helpdesk_rewards_list_filter_by_status
			filter = [
				{ property:'active', value: false }
			].to_json
			get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
            first = data[:values].first
			assert_equal false, first[:active]
        end

        def test_get_helpdesk_rewards_list_search_by_name
			filter = [
				{ property: 'query', value: 'cooker' }
			].to_json
			get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
		end

        def test_get_helpdesk_rewards_list_search_by_code
			filter = [
				{ property: 'query', value: 'el0001' }
			].to_json
			get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
		end

        # def test_get_helpdesk_rewards_list_filter_by_points_range
		# 	filter = [
		# 		{ property: 'min_points', value: '100' },
		# 		{ property: 'max_points', value: '1000' }
		# 	].to_json
		# 	get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
		# 	assert_equal 200, last_response.status
		# 	data = indifferent_data(JSON.parse(last_response.body))
		# 	assert_not_nil data
		# 	assert data[:success]
		# 	assert_true data[:values].is_a? Array
		# end

		def test_get_helpdesk_rewards_list_filter_by_category
			filter = [
				{ property: 'category_id', value: @category.id }
			].to_json
			get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
		end

		def test_get_helpdesk_rewards_list_filter_by_category_and_subcategory
			filter = [
				{ property: 'category_id', value: @category.id },
				{ property: 'sub_category_id', value: @subcategory.id }
			].to_json
			get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, filter: filter}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
		end

        # def test_get_helpdesk_rewards_list_sorted_by_points
        #     sorter = [
		# 		{ property: 'points', direction: 'DESC' }
        #     ].to_json

        #     get '/helpdesk/catalogue/rewards', {token: @token, page: 1, start: 0, limit: 25, sort: sorter}
		# 	assert_equal 200, last_response.status
		# 	data = indifferent_data(JSON.parse(last_response.body))
		# 	assert_not_nil data
		# 	assert data[:success]
        #     assert_not_nil data[:total]
		# 	assert_true data[:values].is_a? Array

		# 	first = data[:values].first
		# 	last = data[:values].last

		# 	isGreater = first[:points] > last[:points]
		# 	assert isGreater
        # end

    end

    context 'helpdesk -  upload rewards using excel' do

		def setup
            create_helpdesk_user
            post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
            @token = data[:values][:token]


        end

        def test_upload_rewards
            filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/Elevatoz - Catalog Sample.xlsx'))
			mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

            post "/helpdesk/catalogue/rewards", {token: @token,
                file: Rack::Test::UploadedFile.new(filepath,mime_type,binary=true)
            }
            assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
		end
    end

	context 'helpdesk - update reward' do
		def setup
            create_helpdesk_user
            create_rewards

			post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]

			get "/helpdesk/catalogue/rewards", {page: 1, start: 0, limit: 25, token: @token}
            data = indifferent_data(JSON.parse(last_response.body))
			@record = data[:values][0]

			@sub_category_id = SubCategory.first.id
			@category_id = SubCategory.first.category_id
		end


        def test_udpate_reward

			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'update model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'update model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_update_thumbnail_file_upload
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'update model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true,
				reward_thumbnail_pic: Rack::Test::UploadedFile.new(filepath, mime_type)
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'update model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
            assert_equal true, data[:values][:active]
			assert_equal @record[:code].downcase + '-a.jpeg', data[:values][:thumbnail].split('/').last.split('?').first
		end

		def test_udpate_reward_update_image_file_upload
			filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
			mime_type = 'image/jpeg'

			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'update model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true,
				reward_image_pic: Rack::Test::UploadedFile.new(filepath, mime_type)
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'update model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
			assert_equal @record[:code].downcase + '-b.jpeg', data[:values][:image].split('/').last.split('?').first
		end

		def test_udpate_reward_set_status_inactive
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'update model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: false
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'update model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
            assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal false, data[:values][:active]
		end

		def test_udpate_reward_name_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: nil,
				model_number: 'update model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal @record[:name], data[:values][:name]
			assert_equal 'update model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_model_number_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: nil,
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal @record[:model_number], data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_brand_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'updated model number',
				brand: nil,
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'updated model number', data[:values][:model_number]
			assert_equal @record[:brand], data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_description_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'updated model number',
				brand: 'updated brand',
				description: nil,
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'updated model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal @record[:description], data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_points_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'updated model number',
				brand: 'updated brand',
				description: 'updated description',
				points: nil,
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'updated model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal @record[:points], data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_category_id_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'updated model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: nil,
				sub_category_id: @sub_category_id,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'updated model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @record[:category_id], data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_sub_category_id_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'updated model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: nil,
				active: true
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'updated model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @record[:sub_category_id], data[:values][:sub_category_id]
			assert_equal true, data[:values][:active]
		end

		def test_udpate_reward_status_not_present
			post "/helpdesk/catalogue/rewards/#{@record[:id]}", {
				token: @token,
				name: 'updated name',
				model_number: 'updated model number',
				brand: 'updated brand',
				description: 'updated description',
				points: '100',
				category_id: @category_id,
				sub_category_id: @sub_category_id,
				active: nil
			}

			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_not_nil true, data[:values]
			assert_equal 'updated name', data[:values][:name]
			assert_equal 'updated model number', data[:values][:model_number]
			assert_equal 'updated brand', data[:values][:brand]
			assert_equal 'updated description', data[:values][:description]
			assert_equal 100, data[:values][:points]
			assert_equal @category_id, data[:values][:category_id]
			assert_equal @sub_category_id, data[:values][:sub_category_id]
			assert_equal @record[:active], data[:values][:active]
		end

	end

	context 'helpdesk - get all reward brands' do
		def setup
			create_helpdesk_user

            post "/helpdesk/auth/login", data={email: $hduser_email, password:  $hduser_password}.to_json
			data = indifferent_data(JSON.parse(last_response.body))
			@token = data[:values][:token]
		end

		def test_get_all_brands
			get '/helpdesk/catalogue/rewards/brands', {token: @token}
			assert_equal 200, last_response.status
			data = indifferent_data(JSON.parse(last_response.body))
			assert_not_nil data
			assert data[:success]
			assert_true data[:values].is_a? Array
		end
	end

end