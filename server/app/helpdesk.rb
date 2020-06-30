class App < Roda

    route 'helpdesk' do |r|
        body = request.body.read
		request.body.rewind
		data = JSON.parse(body) rescue {}
        data = indifferent_data(data)

        data[:user_agent] = request.user_agent

		r.post 'auth/login' do
			token = HelpDeskUser.login data
			ret = {
				token: token
			}

			{
				values: ret,
				success: true
			}
		end

		token = data[:token] || params[:token] || nil
		raise "Invalid login" if token.nil?

		device = Device.where(:token => token).last
		raise "Invalid login" if !device
		@hduser = device.helpdeskuser

		r.on 'users' do
			r.on Integer do |participant_id|
				participant = Participant.not_deleted.where(id: participant_id.to_i).first
				raise 'Invalid User' if !participant

				r.get 'redemptionhistory' do

					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					sorter = nil
					if params[:sort]
						all_sorters = JSON.parse params[:sort]
						sorter = all_sorters.first
					end

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_participant_redeemhistory participant, start, page, limit, filters, sorter

					{
						values: records,
						total: total,
						success: true
					}
				end

				r.get 'earnhistory' do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10
					type = params[:type].to_s
					sorter = nil
					if params[:sort]
						all_sorters = JSON.parse params[:sort]
						sorter = all_sorters.first
					end

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_participant_earnhistory participant, start, limit, filters, sorter , type
					{
						values: records,
						total: total,
						success: true
					}
				end


				r.post 'otp' do
					message = @hduser.set_participant_update_otp participant
					{
						values: message,
						success: true
					}
				end

				r.put do
					if !data[:active].nil? || !params[:active].nil?
						ret = @hduser.update_participant_status data, participant

						{
							success: true
						}
					else
						ret = @hduser.update_participant_details data, participant

						{
							success: true,
							values: ret
						}
					end
				end
			end

			r.on 'download' do
				r.get String do
					response['Content-Type'] = 'text/csv'

					filters = JSON.parse params[:filter] if params[:filter]

					@hduser.users_download filters
				end
			end

			r.get do
				page = params[:page].to_i || 1
				start = params[:start].to_i || 1
				limit = params[:limit].to_i || 10

				sorter = nil
				if params[:sort]
					sorter = params[:sort]
				end

				filters = JSON.parse params[:filter] if params[:filter]

				records, total = @hduser.get_participants start, page, limit, filters, sorter
				{
					values: records,
					total: total,
					success: true
				}
			end
		end

		r.get 'cities' do
			if params[:query]
				ret = City.search params
			elsif params[:state_id]
				ret = City.get params
			else
				raise 'query param or state id required'
			end

			{
				values: ret,
				success: true
			}

		end

		r.get 'states' do
			ret = State.get
			{
				values: ret,
				success: true
			}
		end

		r.on 'requests' do

			r.on Integer do |rec_id|
				rec = HelpDeskRequest.not_deleted.where(id: rec_id.to_i).first
				raise 'Invalid record' if !rec

				r.put do
					ret = @hduser.update_request rec, data

					{
						values: ret,
						success: true
					}
				end

				r.delete do
					if params[:permanent].to_s == "true"
						@hduser.destroy_request rec
					else
						@hduser.register_user rec
					end

					{
						success: true
					}
				end
			end

			r.get 'supervisor' do
				raise 'invalid mobile' if !params[:mobile]
				raise 'invalid role' if !params[:role]

				ret = @hduser.search_supervisor params

				{
					values: ret,
					success: true
				}
			end

			r.on 'download' do
				r.get String do
					response['Content-Type'] = 'text/csv'

					filters = JSON.parse params[:filter] if params[:filter]

					@hduser.requests_download filters
				end
			end

			r.get do
				page = params[:page].to_i || 1
				start = params[:start].to_i || 1
				limit = params[:limit].to_i || 10

				sorter = nil
				if params[:sort]
					sorter = params[:sort]
				end

				filters = JSON.parse params[:filter] if params[:filter]

				records, total = @hduser.get_requests page, limit, filters, sorter

				{
					values: records,
					total: total,
					success: true
				}
			end

			r.post do
				ret = @hduser.upload_requests params

				{
					values: ret,
					success: true
				}
			end
		end

		r.on 'catalogue' do
			r.on 'categories' do
				r.get 'all' do
					ret = @hduser.get_all_categories
					{
						success: true,
						values: ret
					}
				end

				r.on Integer do |category_id|
					category = Category[category_id.to_i]
					raise 'Invalid Category' if !category

					r.on 'subcategories' do
						r.delete Integer do |subcategory_id|
							subcategory = SubCategory[subcategory_id.to_i]
							raise 'Invalid Sub Category' if !subcategory

							@hduser.delete_subcategory subcategory

							{
								success: true
							}
						end
					end

					r.get do
						ret,subs,brands = @hduser.get_reward_by_category category
						{

							value:ret,
							subcategories: subs,
							brands: brands,
							success:true
						}
					end

					r.post do
						ret=@hduser.update_category category,params
						{
							success:true,
							values:ret
						}

					end

					r.delete do
						@hduser.delete_category category
						{
							success:true,
						}
					end

				end

				r.post do
					ret=@hduser.add_category params

					{
						success:true,
						values:ret
					}

				end


			end

			r.on 'rewards' do
				r.get 'brands' do
					ret = @hduser.get_reward_brands

					{
						success: true,
						values: ret
					}
				end

				r.on Integer do |rec_id|
					rec = Reward.where(id: rec_id.to_i).first
					raise 'Invalid record' if !rec

					r.post do
						ret = @hduser.update_reward rec, params, data

						{
							success: true,
							values: ret
						}
					end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					sorter = nil
					if params[:sort]
						all_sorters = JSON.parse params[:sort]
						sorter = all_sorters.first
					end

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_all_rewards page, limit, filters, sorter
					{
						values: records,
						total: total,
						success: true
					}
				end

				r.post do
					ret = @hduser.upload_rewards params

					{
						values: ret,
						success: true
					}
				end
			end

			r.on 'gallery' do
				r.on 'thumbnails' do
					r.post do
						@hduser.upload_gallery_thumbnails params

						{
							success: true
						}
					end

					r.get do
						ret = @hduser.get_gallery_thumbnails

						{
							values: ret,
							success: true
						}
					end
				end

				r.on 'images' do
					r.post do
						@hduser.upload_gallery_images params

						{
							success: true
						}
					end

					r.get do
						ret = @hduser.get_gallery_images

						{
							values: ret,
							success: true
						}
					end
				end
			end
		end

		r.on 'coupons' do

			r.on 'download' do
				r.get String do
					response['Content-Type'] = 'text/csv'

					filters = JSON.parse params[:filter] if params[:filter]

					@hduser.coupons_download filters
				end
			end

			r.get do
				page = params[:page].to_i || 1
				start = params[:start].to_i || 1
				limit = params[:limit].to_i || 10

				sorter = nil
				if params[:sort]
					sorter = params[:sort]
				end

				filters = JSON.parse params[:filter] if params[:filter]

				records, total = @hduser.get_coupons page, limit, filters

				{
					values: records,
					total: total,
					success: true
				}
			end

			r.post do
				ret = @hduser.upload_coupons params
				{
					values: ret,
					success: true
				}
			end
		end

		r.on 'uploadpoints' do
			r.post 'verify' do

				ret = @hduser.upload_points_verify data[:recs]
				success = ret.empty? ? true : false

				{
					success: success,
					values: ret
				}
			end

			r.post 'submit' do
				ret = @hduser.upload_points data[:recs]
				success = ret.empty? ? true : false

				{
					success: success,
					values: ret
				}
			end
		end

		r.on 'orders' do
			r.on Integer do |order_id|
				order = Order[order_id]
				raise "Invalid order" if !order

				r.put do
					ret = @hduser.update_order data, order

					{
						success: true,
						values: ret
					}
				end

			end

			r.post do
				ret = @hduser.order_update_details params
				{
					success: true,
					values: ret
				}
			end

			r.get do
				page = params[:page].to_i || 1
				start = params[:start].to_i || 1
				limit = params[:limit].to_i || 10

				sorter = nil
				if params[:sort]
					sorter = params[:sort]
				end

				filters = JSON.parse params[:filter] if params[:filter]

				records, total = @hduser.get_orders page, limit, filters, sorter
				{
					values: records,
					total: total,
					success: true
				}
			end
		end

		r.on 'banners' do
			r.on 'deletebanner'do
				r.post do
					@hduser.delete_banners params
					{
						success: true
					}
				end
			end

			r.post do
				@hduser.upload_banners params

				{
					success: true
				}
			end

			r.get do
				ret = @hduser.get_banners
				{
					values: ret,
					success: true
				}
			end
		end

		r.on 'lne' do
			r.on 'topics' do

				r.on Integer do |topic_id|
					topic = Topic[topic_id]
					raise "Invalid Topic" if !topic

					r.post "publish" do
						ret = @hduser.publish_topic topic, data
						{
							values: ret,
							success: true
						}
					end


					r.on 'questions' do

						r.on Integer do |question_id|
							question = Question[question_id]
							raise "Invalid Question" if !question
							if topic[:attempted]
								raise "Can't Edit Attempted topic"
							end

							r.put do
								ret = @hduser.update_lne_question question, data

								{
									success: true,
									values: ret
								}
							end

							r.delete do
								@hduser.delete_question question
								{
									success: true
								}
							end
						end

						r.post do
							if topic[:attempted]
								raise "Can't Edit attempted topic"
							end
							ret = @hduser.add_lne_question topic, data
							{
								values: ret,
								success: true
							}
						end

						r.get do

							ret = topic.get_all_question
							# ret = @hduser.get_all_question topic
							# ret = Question.get_all_question topic
							{
								values: ret,
								success: true
							}
						end
					end

					r.post do
						ret = @hduser.update_topic params, topic

						{
							success: true,
							values: ret
						}
					end

					r.delete do
						@hduser.delete_topic topic
						{
							success: true
						}
					end


				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_all_topics page, limit, filters
					{
						values: records,
						total: total,
						success: true
					}
				end

				r.post do

					ret = @hduser.add_lne_topic params, data
					{
						values: ret,
						success: true
					}
				end
			end

		end

		r.on 'levels' do
			r.on 'titles' do
				r.on Integer do |title_id|
					level_title = Level[title_id]
					raise "Invalid Title" if !level_title

					r.post "publish" do

						ret = @hduser.publish_level_title level_title, data
						{
							values: ret,
							success: true
						}
					end


					r.on 'questions' do

						r.on Integer do |question_id|
							question = Levelquestion[question_id]
							raise "Invalid Question" if !question
							if level_title[:published]
								raise "Can't Edit Attempted topic"
							end

							r.put do
								ret = @hduser.update_lne_question question, data

								{
									success: true,
									values: ret
								}
							end

							r.delete do
								@hduser.level_delete_question question
								{
									success: true
								}
							end
						end

						r.post do
							if level_title[:published]
								raise "Can't Edit attempted topic"
							end
							ret = @hduser.add_levels_question level_title, data
							{
								values: ret,
								success: true
							}
						end

						r.get do

							ret = level_title.get_all_levels_question
							# ret = @hduser.get_all_question topic
							# ret = Question.get_all_question topic
							{
								values: ret,
								success: true
							}
						end
					end

					r.post do
						ret = @hduser.update_levels_title params, level_title

						{
							success: true,
							values: ret
						}
					end

					r.delete do
						@hduser.delete_title level_title
						{
							success: true
						}
					end


				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]
					level = JSON.parse params[:level] if params[:level]

					records, total = @hduser.get_all_titles level, page, limit, filters
					{
						values: records,
						total: total,
						success: true
					}
				end

				r.post do
					ret = @hduser.add_levels_title params, data
					{
						values: ret,
						success: true
					}
				end
			end
		end

		r.on 'reports' do
			r.on 'loginreport' do
				r.on 'download' do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]

						if !ENV['RACK_ENV'].include? 'test'
							@hduser.loginreport_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records = @hduser.get_loginreport start, page, limit, filters

					{
						values: records,
						success: true
					}
				end
			end

			r.on 'registration' do
				r.on 'download' do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]
						if !ENV['RACK_ENV'].include? 'test'
							@hduser.registration_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10
					sorter = nil
					if params[:sort]
						sorter = params[:sort]
					end

					filters = JSON.parse params[:filter] if params[:filter]

					records,total = @hduser.get_participants start, page, limit, filters, sorter

					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'quiz' do
				r.on 'download' do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]
						if !ENV['RACK_ENV'].include? 'test'
							@hduser.quizreport_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10


					filters = JSON.parse params[:filter] if params[:filter]

					records,total = @hduser.get_quiz_report start, page, limit, filters

					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'claim' do
				r.on 'download' do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]
						if !ENV['RACK_ENV'].include? 'test'
							@hduser.claimsreport_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10


					filters = JSON.parse params[:filter] if params[:filter]

					records,total = @hduser.get_claims start, page, limit, filters
					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'points' do
				r.on "download" do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]
						if !ENV['RACK_ENV'].include? 'test'
							@hduser.get_points_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_points page, start, limit, filters

					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'redemption' do
				r.on Integer do |order_id|
					order = Order[order_id]
					raise "invalid Order" if !order
					recs = order.get_details

					{
						values: recs,
						success: true
					}
				end
				r.on "download" do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]
						if !ENV['RACK_ENV'].include? 'test'
							@hduser.redemption_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_redemption start, page, limit, filters

					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'levels' do
				r.on "download" do
					# r.get String do |csv_filename|
					# 	response['Content-Type'] = 'text/csv'

						filters = JSON.parse params[:filter] if params[:filter]
						if !ENV['RACK_ENV'].include? 'test'
							@hduser.levelsreport_download filters
						end
						{
							success: true
						}
					# end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_levels_report start, page, limit, filters

					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'reportrequest' do
				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @hduser.get_request_report start, page, limit, filters

					{
						values: records,
						total: total,
						success: true
					}
				end
			end
		end
	end
end