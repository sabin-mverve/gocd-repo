require_relative '0 helper/helper'

class Testclass < SequelTestCase
		include Rack::Test::Methods

		def app
			App.app
		end

		context 'helpdesk - get all reward categories ' do
			def setup
				create_helpdesk_user
				create_rewards

				post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
				data = indifferent_data(JSON.parse(last_response.body))
				@token = data[:values][:token]
			end

			def test_helpdesk_get_all_reward_categories
				get "/helpdesk/catalogue/categories/all", {token: @token}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal true, data[:success]
				assert_not_nil data[:values]
				assert_not_nil data[:values].first[:rewards_count]
				assert_not_nil data[:values].first[:image]
				assert_equal Array, data[:values].class

				assert_equal Array, data[:values].first[:subcategories].class
				# assert_not_nil data[:values].first[:subcategories].first[:rewards_count]
			end
		end

		context 'helpdesk - adding a new category and subcategories' do
			def setup
				create_helpdesk_user
				create_rewards

				post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
				data = indifferent_data(JSON.parse(last_response.body))
				@token = data[:values][:token]

				@category = Category.first
			end

			def test_helpdesk_add_new_category_no_subcategory
				filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
				mime_type = 'image/jpeg'

				post "/helpdesk/catalogue/categories" , {
					token: @token,
					category_name: 'new category',
					subcategories: '[]',
					category_pic: Rack::Test::UploadedFile.new(filepath, mime_type)
				}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert data[:success]
				assert_not_nil data[:values]
				assert_equal 'New Category', data[:values][:category][:name]
				assert_equal [], data[:values][:subcategories]
				assert_not_nil Category.where(name: data[:values][:category][:name]).first[:image]
				assert_equal 'new-category.jpeg', Category.where(name: data[:values][:category][:name]).first[:image]
			end

			def test_helpdesk_add_new_category_already_exists
				post "/helpdesk/catalogue/categories" , {token: @token, category_name: @category[:name]}
				assert_equal 500, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal false, data[:success]
				assert_not_nil data[:error]
			end

			def test_helpdesk_add_new_category_valid_subcategory
				post "/helpdesk/catalogue/categories" , {token: @token, category_name: 'new category', subcategories: '["subcategory one", "subcategory two"]'}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert data[:success]
				assert_not_nil data[:values]
				assert_equal 'New Category', data[:values][:category][:name]

				assert_equal Array, data[:values][:subcategories].class
				assert_not_nil data[:values][:subcategories]
				assert_equal 'Subcategory Two', data[:values][:subcategories].last[:name]
			end

			def test_helpdesk_add_new_category_invalid_subcategory
				# test case to test if the subcategory alreadly exists in that particular category
				post "/helpdesk/catalogue/categories" , {token: @token, category_name: 'new category', subcategories: '["subcategory one", "subcategory one"]'}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert data[:success]
				assert_not_nil data[:values]
				assert_equal 'New Category', data[:values][:category][:name]

				assert_equal Array, data[:values][:subcategories].class
				assert_not_nil data[:values][:subcategories]
				assert_equal 'Subcategory One', data[:values][:subcategories].first[:name]

				assert_equal Array, data[:values][:subcategories].class
				# assert_equal [], data[:values][:subcategories_skipped]
			end

		end

		context 'helpdesk - edit a category' do
			def setup
				create_helpdesk_user
				create_rewards

				post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
				data = indifferent_data(JSON.parse(last_response.body))
				@token = data[:values][:token]

				get "/helpdesk/catalogue/categories/all", {token: @token, participant_id: @participant_id}
				data = indifferent_data(JSON.parse(last_response.body))
				@category = data[:values][0]

				# @category_id = data[:values][0][:id]
				# @category_name = data[:values][0][:name]
				# @subcategories = data[:]
			end

			def test_update_category_name_and_image
				filepath = File.expand_path(File.join(File.dirname(__FILE__), '0 helper/test.jpg'))
				mime_type = 'image/jpeg'

				post "/helpdesk/catalogue/categories/#{@category[:id]}", {
					token: @token,
					category_name: 'updated category name',
					subcategories: '[]',
					category_pic: Rack::Test::UploadedFile.new(filepath, mime_type)
				}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal true, data[:success]
				assert_not_nil data[:values]
				assert_equal Array, data[:values][:subcategories].class
				assert_equal 'Updated Category Name', data[:values][:category][:name]
				assert_not_nil Category.where(name: data[:values][:category][:name]).first[:image]
				assert_equal 'updated-category-name.jpeg', Category.where(name: data[:values][:category][:name]).first[:image]
			end

			def test_update_category_name_not_present
				post "/helpdesk/catalogue/categories/#{@category[:id]}", {
					token: @token,
					category_name: nil,
					subcategories: '[]'
				}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal true, data[:success]
				assert_not_nil data[:values]
				assert_equal Array, data[:values][:subcategories].class
				assert_equal @category[:name], data[:values][:category][:name]
			end

			def test_update_category_add_new_subcategory
				subcategories = [{name: 'new subcategory', id: nil}].to_json
				post "/helpdesk/catalogue/categories/#{@category[:id]}", {
					token: @token,
					category_name: @category[:name],
					# subcategories: '["new subcategory"]'
					# subcategories: '["{name: new subcategory, id: null}"]'
					subcategories: subcategories
				}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal true, data[:success]
				assert_not_nil data[:values]
				assert_equal @category[:name], data[:values][:category][:name]
				assert_equal Array, data[:values][:subcategories].class
				assert_equal 'New Subcategory', data[:values][:subcategories].last[:name]
			end

			def test_update_category_update_subcategory
				subcategories = [{name: 'updated sub category', id: @category[:subcategories].first[:id]}].to_json
				post "/helpdesk/catalogue/categories/#{@category[:id]}", {
					token: @token,
					category_name: @category[:name],
					subcategories: subcategories
				}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal true, data[:success]
				assert_not_nil data[:values]
				assert_equal @category[:name], data[:values][:category][:name]
				assert_equal Array, data[:values][:subcategories].class
				assert_equal 'Updated Sub Category', data[:values][:subcategories].first[:name]
			end

		end

		context 'helpdesk - delete a category' do
			def setup
				create_helpdesk_user
				create_rewards

				post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
				data = indifferent_data(JSON.parse(last_response.body))
				@token = data[:values][:token]

				get "/helpdesk/catalogue/categories/all", {token: @token, participant_id: @participant_id}
				data = indifferent_data(JSON.parse(last_response.body))
				@category_with_rewards = data[:values].last

				post "/helpdesk/catalogue/categories" , {token: @token, category_name: 'new category', subcategories: '["subcategory one"]'}
				data = indifferent_data(JSON.parse(last_response.body))
				@category_with_no_rewards = data[:values]

			end

			def test_delete_category_rewards_present
				delete "/helpdesk/catalogue/categories/#{@category_with_rewards[:id]}", {token: @token}
				assert_equal 500, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal false, data[:success]
				assert_not_nil data[:error]
			end

			def test_delete_category_rewards_not_present
				delete "/helpdesk/catalogue/categories/#{@category_with_no_rewards[:category][:id]}", {token: @token}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert data[:success]
				assert_nil Category.where(id: @category_with_no_rewards[:category][:id]).first
			end

		end

		context 'helpdesk - delete a subcategory' do
			def setup
				create_helpdesk_user
				create_rewards

				post "/helpdesk/auth/login", {email: $hduser_email, password:  $hduser_password}.to_json
				data = indifferent_data(JSON.parse(last_response.body))
				@token = data[:values][:token]

				get "/helpdesk/catalogue/categories/all", {token: @token, participant_id: @participant_id}
				data = indifferent_data(JSON.parse(last_response.body))
				@category_with_rewards = data[:values].last
				@subcategory_with_rewards = @category_with_rewards[:subcategories].first

				post "/helpdesk/catalogue/categories" , {token: @token, category_name: 'new category', subcategories: '["subcategory one"]'}
				data = indifferent_data(JSON.parse(last_response.body))
				@category_with_no_rewards = data[:values]
				@subcategory_with_no_rewards = @category_with_no_rewards[:subcategories].first
			end

			def test_delete_sub_category_rewards_present
				delete "/helpdesk/catalogue/categories/#{@category_with_rewards[:id]}/subcategories/#{@subcategory_with_rewards[:id]}", {token: @token}
				assert_equal 500, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert_equal false, data[:success]
				assert_not_nil data[:error]
			end

			def test_delete_sub_category_rewards_not_present
				delete "/helpdesk/catalogue/categories/#{@category_with_no_rewards[:category][:id]}/subcategories/#{@subcategory_with_no_rewards[:id]}", {token: @token}
				assert_equal 200, last_response.status
				data = indifferent_data(JSON.parse(last_response.body))
				assert_not_nil data
				assert data[:success]
				assert_nil SubCategory.where(id: @subcategory_with_no_rewards[:id]).first
			end
		end

end