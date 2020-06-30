SECRET='lnd848dd10327'

class App < Roda

    route 'participant' do |r|
        body = request.body.read
		request.body.rewind
		data = JSON.parse(body) rescue {}
        data = indifferent_data(data)

		data[:user_agent] = request.user_agent

		# ==================================== #
		# Following API is  for ValueFirst SMS #
		# ==================================== #
		r.on 'sms' do
			ret = Participant.feedback_via_sms params
			ret
		end


		r.post 'mobile' do
			Participant.verify data

			{
				success: true
			}
		end

		r.post 'login' do
			ret = Participant.login data

			{
				values: ret,
				success: true
			}
		end

		r.get 'version' do
			ret = Participant.version_check params
			{
				values: ret,
				success: true
			}
		end

		token = data[:token] || params[:token] || nil
		raise "Invalid participant" if token.nil?

		device = Device.where(token: token).last
		raise "Invalid participant" if !device
		@participant = device.participant_dataset.where(active: true).first
		raise "Invalid participant" if !@participant


		r.get 'dashboard' do
			ret = @participant.get_all_points
			{
				values: ret,
				success: true
			}
		end

		r.on 'dealers' do

			r.get 'associate_rsa' do
				raise "Invalid Participant" if @participant.permission.role_name != 'dl'

				page = params[:page].to_i || 1
				start = params[:start].to_i || 1
				limit = params[:limit].to_i || 10

				filters = JSON.parse params[:filter] if params[:filter]

				ret, total =  @participant.get_associate_rsa page, limit, filters
				{
					values: ret,
					total: total,
					success:true
				}
			end

			r.on 'poolpoints' do
				raise "Invalid Participant" if @participant.permission.role_name != 'dl'
				r.on Integer do |rsa_id|
					@rsa = Participant.not_deleted.where(id: rsa_id.to_i).first
					raise 'Invalid Rsa' if !@rsa

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

						records, total = @rsa.earnpoints_history start, limit, filters, sorter ,type
						{
							values: records,
							total: total,
							success: true
						}
					end
				end

				r.get do

					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					ret,total =  @participant.get_total_pool_points page, limit, filters
					{
						values: ret,
						total: total,
						success:true
					}
				end
			end

			r.get 'quizstatus' do
				raise "Invalid Participant" if @participant.permission.role_name != 'dl'

				page = params[:page].to_i || 1
				start = params[:start].to_i || 1
				limit = params[:limit].to_i || 10

				filters = JSON.parse params[:filter] if params[:filter]

				ret =  @participant.get_dealer_quiz_status page, limit, filters
				{
					values: ret,
					success:true
				}
			end
		end
		r.on 'cart' do

			r.post 'checkout' do
				@participant.checkout data
				{
					success: true
				}
			end

			r.on Integer do |cartitem_id|
				r.delete do
					ret = @participant.remove_from_cart cartitem_id

					{
						success: true
					}
				end

				r.put do
					raise 'Invalid quantity' if !data[:quantity] or data[:quantity].to_i <= 0

					ret = @participant.update_cartitem_quantity cartitem_id, data[:quantity].to_i

					{
						values: ret,
						success: true
					}
				end

			end


			r.get do
				ret = @participant.get_cartitems

				{
					values: ret,
					success: true
				}

			end


			r.post do
				ret = @participant.add_to_cart data

				{
					values: ret,
					success: true
				}

			end

		end

		r.on 'address' do
			r.on Integer do |address_id|
				r.delete do
					ret = @participant.remove_address address_id

					{
						success: true
					}
				end
			end
			r.get do
				ret = @participant.get_addresses
				{
					values: ret,
					success: true
				}
			end
			r.post do
				ret = @participant.new_address data
				{
					values: ret,
					success: true
				}
			end
		end

		r.on 'order' do
			r.on Integer do |order_id|

				if params[:sort]
					all_sorters = JSON.parse params[:sort]
					sorter = all_sorters.first
				end

				filters = JSON.parse params[:filter] if params[:filter]

				orderitems = @participant.get_order_details order_id, filters, sorter
				{
					values: orderitems,
					success: true
				}
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
				records, total = @participant.get_orders page, limit, filters, sorter

				{
					values: records,
					total: total,
					success: true
				}
			end
		end

		r.on 'refer' do
			raise "Only dealers allowed" if @participant.permission.role_name != 'dl'
			r.post do
				ret = @participant.refer_another data

				{
					values: ret,
					success: true
				}
			end
		end

		r.get 'states' do
			ret = State.collect do |state|
				{
					id: state.id,
					name: state.name
				}
			end
			{
				values: ret,
				success: true
			}
		end

		r.on 'cities' do
			r.get 'search' do
				raise 'query param is required' if !params[:query]
				ret = City.search params
				{
					values: ret,
					success: true
				}
            end

			r.get do
				ret = City.collect do |city|
					{
						id: city.id,
						name: city.name,
						state_id: city.state_id
					}
				end
				{
					values: ret,
					success: true
				}
			end
		end

		r.on 'claim' do
			r.post 'verify' do
				ret = @participant.verify_coupon data
				{
					values: ret,
					success: true
				}
			end

			r.post do
				data[:via] = 'app'
				@participant.make_claim data

				{
					success: true
				}
			end
		end

		r.on 'knowledge' do

			r.post do
				ret = Knowledge_bank.mattress data
				{
					values: ret,
					success: true
				}
			end
		end

		r.on 'banners' do
			r.get do
				ret = @participant.get_banners
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

					r.on 'questions' do
						r.get do

							ret = topic.get_all_question_partcipant
							{
								values: ret,
								success: true
							}
						end
					end

					r.post do
						ret = @participant.submit_answers data, topic
						{
							values: ret,
							success: true
						}
					end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @participant.get_topics_participant page, limit, filters
					{
						values: records,
						total: total,
						success: true
					}
				end
			end
		end

		r.on 'levels' do
			r.on 'titles' do

				r.on Integer do |title_id|
					level_title = Level[title_id]
					raise "Invalid Topic" if !level_title

					r.on 'questions' do
						r.get do

							ret = level_title.get_all_levels_question_partcipant
							{
								values: ret,
								success: true
							}
						end
					end

					r.on 'materials' do
						r.on Integer do |material_id|
							material = Material[material_id]
							raise "Invalid Material" if !material

							r.post do
								ret = @participant.submit_material_counter data, material
								{
									values: ret,
									success: true
								}
							end
						end
					end

					r.on 'attempted' do
						r.post do
							ret = @participant.submit_title_attempt data, level_title
							{
								values: ret,
								success: true
							}
						end
					end

					r.post do
						ret = @participant.submit_levels_answers data, level_title
						{
							values: ret,
							success: true
						}
					end
				end

				r.get do
					page = params[:page].to_i || 1
					start = params[:start].to_i || 1
					limit = params[:limit].to_i || 10

					filters = JSON.parse params[:filter] if params[:filter]

					records, total = @participant.get_level_titles_participant  page, limit, filters
					{
						values: records,
						total: total,
						success: true
					}
				end
			end

			r.on 'certificates' do
				r.get do

					ret = @participant.get_all_certificate
					{
						values: ret,
						success: true
					}
				end
			end
		end

		# * ============================================================================= #
		# *  - - - - - - Common Module - - - - - -   #
		# * ============================================================================= #

		r.on 'earnhistory' do
			r.on 'claim' do
				r.get do
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

					records, total = @participant.earnpoints_history start, limit, filters, sorter ,type
					{
						values: records,
						total: total,
						success: true
					}
				end
			end
		end

		r.on 'catalogue' do
			r.on 'categories' do
				r.on Integer do |category_id|
					category = Category[category_id.to_i]
					raise "Invalid category" if !category

					r.get 'subcategories' do
							ret = category.get_subcategories
						{
							values: ret,
							success: true
						}
					end

					r.get 'rewards' do

						page = params[:page].to_i || 1
						start = params[:start].to_i || 1
						limit = params[:limit].to_i || 10

						sorter = nil
						if params[:sort]
							all_sorters = JSON.parse params[:sort]
							sorter = all_sorters.first
						end

						filters = JSON.parse params[:filter] if params[:filter]

						records, total, max , min = category.get_rewards page, limit, filters, sorter
						{
							values: records,
							total: total,
							max:max,
							min: min,
							success: true
						}
					end
				end


				r.get do
					ret = Category.get
					{
						values: ret,
						success: true
					}
				end
			end
		end

		r.on 'feedback' do
			r.post do
				@participant.submit_customer_number data
				{
					success: true
				}
			end
		end

	end
end
