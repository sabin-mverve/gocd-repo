require 'bundler'
Bundler.require(:default)

require 'securerandom'
require 'sequel/plugins/serialization'

# DB ||= Sequel.sqlite(ENV['DB_FILE'], :timeout => 1000)
DB = Sequel.connect adapter: 'postgres', database: ENV['PG_DB'], user: ENV['PG_USERNAME'], password: ENV['PG_PASSWORD']


Sequel::Model.plugin	:timestamps,
						:create			=> :created_at,
						:update			=> :updated_at,
						:force				=> true,
						:update_on_create	=> true

class State < Sequel::Model(DB[:states])
	plugin :paranoid

	one_to_many     :cities,
					:key    =>  :state_id,
					:class  =>  :City

	def self.search data
		query_string = "#{data['query'].downcase}%"
		self.where(Sequel.like(Sequel.function(:lower, :name), query_string)).collect do |record|
			{
				id: record.id,
				name: record.name
			}
		end
	end

	def self.get
		self.order(:name).collect do |record|
			{
				id: record.id,
				name: record.name
			}
		end
	end

	def all_cities
		self.cities_dataset.order(:name).collect do |record|
			{
				id: record.id,
				name: record.name
			}
		end
	end
end

class City < Sequel::Model(DB[:cities])
	plugin :paranoid

	many_to_one		:state,
					:key	=> :state_id,
					:class	=> :State


	def self.search data
		query_string = "#{data['query'].downcase}%"
		self.where(Sequel.like(Sequel.function(:lower, :name), query_string)).collect do |record|
			{
				city_id: record.id,
				city_name: record.name,
				state_id: record.state.id,
				state_name: record.state.name
			}
		end
	end

	def self.get data
		state_id = data[:state_id]
		self.where(state_id: state_id).order(:name).collect do |record|
			{
				city_id: record.id,
				city_name: record.name,
				state_id: record.state.id,
				state_name: record.state.name
			}
		end
	end
end

class HelpDeskRequest < Sequel::Model(DB[:helpdesk_requests].extension(:pagination))

	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:city,
					:key	=> :city_id,
					:class	=> :City

	many_to_one		:state,
					:key	=> :state_id,
					:class	=> :State

end #HelpDeskRequest

class HelpDeskUser < Sequel::Model(DB[:users].filter(role: 'h'))
	plugin :validation_helpers
	plugin :paranoid

	one_to_one		:device,
					:key    	=> :user_id,
					:class		=> :Device

	one_to_many		:reportdownloadrequests,
					:key	=> :user_id,
					:class	=> :ReportDownloadRequest

	def validate
		super
		validates_unique :email, message: 'already exists'
	end

	def self.login data
		hduser = self.first( email: data[:email] )
		raise "Invalid Login" if !hduser

		device = hduser.device
		raise "Invalid Login" if !device.authenticate data[:password]

		token = SecureRandom.hex(10)
		device.update(
			token: token,
			user_agent: data[:user_agent]
		)

		device.token
	end

	def upload_requests params
		excel_file = params[:file][:tempfile]
		ret = nil

		workbook = Roo::Spreadsheet.open excel_file
		firstsheet = workbook.sheet(0)

		DB.transaction do
			hdrequest_new_counter = 0
			hdrequest_exists_counter = 0
			hdrequest_skipped = 0
			hdrequest_rejected = 0

			records_skipped = []
			records_rejected = []

			firstsheet.each_with_index(
				participant_type: 'Paricipant Type',
				name: 'Participant Name',
				mobile: 'Mobile Number',
				email: 'Email id',
				address1: 'Address Line 1',
				address2: 'Address Line 2',
				address3: 'Address Line 3',
				district: 'District',
				city: 'City',
				state: 'State',
				pincode: 'Pin Code',
				store_name: 'Store Name',
				dob: 'DOB',
				doa: 'DOA',
				doj: 'DOJ',
				experience: 'Total Experience',
				qualification: 'Education Qualification',
				mother_tongue: 'Mother Tongue',

			) do |row, ind|
				next if ind < 2

				mobile = row[:mobile].to_i.to_s
				participant_type = row[:participant_type].to_s
				name = row[:name].to_s
				dob = doa = doj = nil
				pincode = row[:pincode].to_s
				address1  = row[:address1 ].to_s
				store_name  = row[:store_name ].to_s

				if mobile.to_s.empty?
					hdrequest_rejected += 1
					records_rejected.push name + ' - Mobile is required'
					next
				end

				if participant_type.empty?
					hdrequest_rejected += 1
					records_rejected.push mobile + ' - User Type Empty '
					next
				end

				if name.empty?
					hdrequest_rejected += 1
					records_rejected.push mobile + ' - Name is Required'
					next
				end

				if address1.empty?
					hdrequest_rejected += 1
					records_rejected.push mobile + ' - Address is Required'
					next
				end

				if row[:city].to_s.empty? or row[:state].to_s.empty? or row[:pincode].to_s.empty?
					hdrequest_rejected += 1
					records_rejected.push mobile + ' - Provide valid city and state'
					next
				end

				if pincode.empty? || pincode.length < 6 || pincode.length > 6
					hdrequest_rejected += 1
					records_rejected.push mobile + ' - Provide valid Pincode'
					next
				end

				if store_name.empty?
					hdrequest_rejected += 1
					records_rejected.push mobile + ' - Store Name is Required'
					next
				end

				if participant_type.downcase == 'rsa'
					participant_type = 'RSA'
				elsif participant_type.downcase == 'dealer'
					participant_type = 'Dealer'
				end

				if mobile.length < 10 or mobile.length > 12 or mobile.length == 11
					hdrequest_skipped += 1
					records_skipped.push mobile
					next
				end

				mobile = "91#{mobile}" if mobile.length == 10

				user_exists = DB[:users].where(mobile: mobile).first

				if user_exists
					hdrequest_skipped += 1
					records_skipped.push mobile
					next
				end

				begin
					dob = Date.parse(row[:dob].to_s) if !row[:dob].nil?
					doa = Date.parse(row[:doa].to_s) if !row[:doa].nil?
					doj = Date.parse(row[:doj].to_s) if !row[:doj].nil?
				rescue ArgumentError
					hdrequest_rejected += 1
					records_rejected.push mobile + "- Invalid date"
					next
				end

				if !row[:state].to_s.empty?
					state = State.where(Sequel.like(Sequel.function(:lower, :name), row[:state].downcase)).first
					if !state
						records_rejected.push mobile + "- Invalid state"
						next
					end

					if !state.nil?
						city = row[:city].to_s.empty? ? nil : state.cities_dataset.where(Sequel.like(Sequel.function(:lower, :name), row[:city].downcase)).first
					end
				end
				if !row[:city].to_s.empty?
					city = City.where(Sequel.like(Sequel.function(:lower, :name), row[:city].downcase)).first

					if !city
						records_rejected.push mobile + "- Invalid city"
						next
					end
					if !city.nil?
						state = city.state
					end
				end

				hdrequest_exists = HelpDeskRequest.where(mobile: mobile).first
				if hdrequest_exists
					hdrequest_exists_counter += 1

					status = nil

					if participant_type.to_s.nil? || name.nil? || address1.to_s.nil? || city.to_s.nil? || state.to_s.nil? || ( pincode.empty? || pincode.length < 6 || pincode.length > 6) || store_name
						status = 'incomplete'
					else
						status = 'complete'
					end

					hdrequest_exists.update(
						type: 'upload',
						status: status,

						participant_type: participant_type,
						name: name,
						mobile: mobile,
						email: row[:email],
						address1: row[:address1],
						address2: row[:address2],
						address3: row[:address3],
						district: row[:district],
						city_id: city.nil? ? nil : city.id,
						state_id: state.nil? ? nil : state.id,
						pincode: pincode,
						store_name: row[:store_name],
						dob: dob,
						doa: doa,
						doj: doj,
						experience: row[:experience],
						qualification: row[:qualification],
						mother_tongue: row[:mother_tongue]
					)
				else
					hdrequest_new_counter += 1
					status = nil
					if participant_type.to_s.nil? || name.nil? || address1.to_s.nil? || city.to_s.nil? || state.to_s.nil? || ( pincode.empty? || pincode.length < 6 || pincode.length > 6) || store_name
						status = 'incomplete'
					else
						status = 'complete'
					end

					HelpDeskRequest.create(
						type: 'upload',
						status: status,

						participant_type: participant_type,
						name: name,
						mobile: mobile,
						email: row[:email],
						address1: row[:address1],
						address2: row[:address2],
						address3: row[:address3],
						district: row[:district],
						city_id: city.nil? ? nil : city.id,
						state_id: state.nil? ? nil : state.id,
						pincode: pincode,
						dob: dob,
						doa: doa,
						doj: doj,
						store_name: row[:store_name],
						experience: row[:experience],
						qualification: row[:qualification],
						mother_tongue: row[:mother_tongue]
					)
				end # if
			end # Roo parse

			if ENV['RACK_ENV'] == 'test'
				puts '---------------------------------------------'
				puts "#{hdrequest_exists_counter} requests were updated"
				puts "#{hdrequest_new_counter} requests were created"
				puts "#{hdrequest_skipped} requests were skipped"
				puts "#{hdrequest_rejected} requests were rejected"
				puts "#{records_skipped} records were skipped"
				puts "#{records_rejected} records were rejected"
				puts '---------------------------------------------'
			end

			ret = {
				updated: hdrequest_exists_counter,
				created: hdrequest_new_counter,
				skipped: hdrequest_skipped,
				rejected: hdrequest_rejected,
				records_skipped: records_skipped,
				records_rejected: records_rejected
			}

		end # DB.transaction

		ret
	end

	def get_requests page, limit, filters, sorter
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = HelpDeskRequest.dataset.not_deleted

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'role'
					ds = ds.where(Sequel.function(:lower, :participant_type) => filter['value'].downcase)
				elsif filter['property'] == 'state'
					ds = ds.where(:state_id => filter['value'])
				elsif filter['property'] == 'city'
					ds = ds.where(:city_id => filter['value'])
				elsif filter['property'] == 'status'
					ds = ds.where(:status => filter['value'].downcase)
				elsif filter['property'] == 'type'
					ds = ds.where(:type => filter['value'].downcase)
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"

					ds = ds.where{Sequel.like(:mobile, query_string) | Sequel.like(Sequel.function(:lower, :name), query_string.downcase) }
				end
			end
		end

		if from_date and to_date
			ds = ds.where(:created_at => from_date..to_date)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rec|

			age = nil

			if !rec.dob.nil?
				date_of_birth = rec.dob

				# Total seconds in a year
				sec = 31557600
				age = ((Time.now - date_of_birth.to_time) / sec).floor
			end

			{
				id: rec.id,
				type: rec.type,
				mobile: rec.mobile,
				email: rec.email,
				created_at: rec.created_at.iso8601,
				participant_type: rec.participant_type,
				name: rec.name,
				address1: rec.address1,
				address2: rec.address2,
				address3: rec.address3,
				city_id: rec.city_id,
				state_id: rec.state_id,
				city_name: rec.city.nil? ? nil : rec.city.name,
				state_name: rec.state.nil? ? nil : State[rec.state_id].name,
				pincode: rec.pincode,
				dob: rec.dob,
				doa: rec.doa,
				doj: rec.doj,
				age: age,
				status: rec.status,
				store_name: rec.store_name,
				experience: rec.experience,
				qualification: rec.qualification,
				mother_tongue: rec.mother_tongue
			}
		end

		return recs, total
	end

	def requests_download filters

		ds = HelpDeskRequest.dataset.not_deleted

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'role'
					ds = ds.where(Sequel.function(:lower,:participant_type) => filter['value'].downcase)
				elsif filter['property'] == 'type'
					ds = ds.where(:type => filter['value'].downcase)
				elsif filter['property'] == 'status'
					ds = ds.where(:status=> filter['value'].downcase)
				elsif filter['property'] == 'state'
					ds = ds.where(:state_id => filter['value'])
				elsif filter['property'] == 'city'
					ds = ds.where(:city_id => filter['value'])
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(:mobile, query_string) | Sequel.like(:name, query_string) }
				end
			end
		end

		if from_date and to_date
			ds = ds.where(:created_at => from_date..to_date)
		end

		recs = ds.collect do |rec|

		rec.mobile[0..1] = ''
			[
				rec.name,
				"=\"#{rec.mobile}\"",
				rec.email,
				rec.type,
				rec.participant_type,
				rec.created_at.iso8601,
				rec.address1,
				rec.address2,
				rec.address3,
				rec.city.nil? ? nil : rec.city.name,
				rec.state.nil? ? nil : rec.state.name,
				rec.pincode,
				rec.dob,
				rec.doa,
				rec.doj,
				rec.status,
				rec.store_name,
				rec.experience,
				rec.qualification,
				rec.mother_tongue
			]
		end

		CSV.generate do |csv|
			csv << ['Name', 'Mobile', 'Email','Type', 'Participant Type', 'Date', 'Address1', 'Address2', 'Address3', 'City', 'State', 'Pincode', 'DOB', 'DOA','DOJ', 'Status', 'Store Name', 'Total Experience', 'Education Qualification', 'Mother Tongue' ]
			recs.each { |row| csv << row }
		end
	end

	def update_request record, data

		city, state, city_id, city_name, state_id, state_name = nil, nil, nil, nil, nil, nil

		city_id = data[:city_id] || record.city_id

		if !city_id.nil?
			city = City[city_id.to_i]
			state = city.state
			city_id = city.id
			state_id = state.id
			city_name = city.name
			state_name = state.name
		end

		record.set(
			participant_type: data[:participant_type].nil? ? record[:participant_type] : data[:participant_type],
			name: data[:name].nil? ? record[:name] : data[:name],
			email: data[:email].nil? ? record[:email] : data[:email],
			address1: data[:address1].nil? ? record[:address1] : data[:address1],
			address2: data[:address2].nil? ? record[:address2] : data[:address2],
			address3: data[:address3].nil? ? record[:address3] : data[:address3],
			doa: data[:doa].to_s.empty? ? record[:doa] : data[:doa],
			dob: data[:dob].to_s.empty? ? record[:dob] : data[:dob],
			doj: data[:doj].to_s.empty? ? record[:doj] : data[:doj],
			city_id: city_id,
			state_id: state_id,
			pincode: data[:pincode].nil? ? record[:pincode] : data[:pincode],
			store_name: data[:store_name].nil? ? record[:store_name] : data[:store_name],
			experience: data[:experience].nil? ? record[:experience] : data[:experience],
			qualification: data[:qualification].nil? ? record[:qualification] : data[:qualification],
			mother_tongue: data[:mother_tongue].nil? ? record[:mother_tongue] : data[:mother_tongue],
		)
		if !record.participant_type.to_s.empty? and record.participant_type.downcase == 'dealer'

			cso_id = record.parent_id || data[:parent_id]
			cso = Participant.where(id: cso_id).first

			raise 'Invalid cso' if !cso

			role = cso.permission
			raise 'Invalid cso' if (role.role_name != 'cso')

			record.set(
				parent_id: cso.id,
				parent_mobile:cso.mobile
			)

		elsif !record.participant_type.to_s.empty? and record.participant_type.downcase == 'rsa'

			dealer_id = record.parent_id || data[:parent_id]
			dealer = Participant.where(id: dealer_id).first

			raise 'Invalid Dealer' if !dealer
			role = dealer.permission
			raise 'Invalid Dealer' if !dealer and (role.role_name != 'dl')

			record.set(
				parent_id: dealer.id,
				parent_mobile: dealer.mobile
			)

		end

		raise record.errors.full_messages.join(', ') if !record.valid?

		if	record.participant_type.to_s.empty? ||
			record.name.to_s.empty? ||
			record.mobile.to_s.empty? ||
			record.address1.to_s.empty? ||
			record.city_id.nil? ||
			record.state_id.nil? ||
			record.pincode.to_s.empty? ||
			record.store_name.to_s.empty?

			record.set(status: 'incomplete')
		else
			record.set(status: 'complete')
		end

		record.save

		{
			id: record.id,
			type: record.type,
			mobile: record.mobile,
			created_at: record.created_at.iso8601,
			participant_type: record.participant_type,
			name: record.name,
			email: record.email,
			address1: record.address1,
			address2: record.address2,
			address3: record.address3,
			city_id: record.city_id,
			state_id: record.state_id,
			pincode: record.pincode,
			dob: record.dob,
			doa: record.doa,
			doj: record.doj,
			status: record.status,
			store_name: record.store_name,
			experience: record.experience,
			qualification: record.qualification,
			mother_tongue: record.mother_tongue
		}
	end

	def search_supervisor params
		mobile_query_string, role_name = nil

		mobile_query_string = "%#{params['mobile'].to_s}%"
		role_name = params['role']

		ds = Participant.dataset.where(Sequel.like(Sequel[:users][:mobile], mobile_query_string))
		ds = ds.where(:active => true)
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id]).where(role_name: role_name)

		ds.collect do |rec|
			{
				id: rec[:user_id],
				mobile: rec[:mobile],
				name: rec[:name]
			}
		end
	end

	def register_user record

		mobile = record[:mobile]
		raise 'Role is required' if !record.participant_type
		raise 'Name is required' if !record.name
		raise 'Address1 is required' if !record.address1
		raise 'City is required' if !record.city
		raise 'State is required' if !record.state
		raise 'Pincode is required' if !record.pincode
		raise 'Please assign to the manager' if record.parent_id.to_s.empty?
		raise 'Store Name is required' if record.store_name.to_s.empty?

		participant = Participant.where(mobile: record.mobile).first
		raise 'Participant already exists' if participant

		DB.transaction do

			participant = Participant.new(
				mobile: record.mobile,
				active: true,
				name: record.name,
				email: record.email,
				role: 'p',
				parent_id: record.parent_id
			)

			raise 'invalid participant type' if !record.participant_type

			if record.participant_type.downcase == 'dealer'
				permissions = {
					role_name: 'dl',
					refer: true
				}
			elsif record.participant_type.downcase == 'rsa'
				permissions = {
					role_name: 'rsa',
					pointsearn: true,
					claim: true,
					cart: true,
					redemption: true,
				}
			end

			participant.permission_attributes = permissions

			raise participant.errors.full_messages.join(', ') if !participant.valid?

			participant.save

			participant.add_address(
				name: record.name,
				mobile: record.mobile,
				address1: record.address1,
				address2: record.address2,
				address3: record.address3,
				city_id: record.city_id,
				state_id: record.state_id,
				pincode: record.pincode
			)

			ParticipantDetail.create(
				user_id: participant.id,
				doa: record.doa,
				dob: record.dob,
				doj: record.doj,
				store_name: record.store_name,
				experience: record.experience,
				qualification: record.qualification,
				mother_tongue: record.mother_tongue
			)
			record.soft_delete

			send_sms_mobile_successfully_registered participant
		end
	end

	def destroy_request rec
		rec.delete
		true
	end

	def get_coupons page, limit, filters
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = Coupon.dataset.not_deleted

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'status'
					if filter['value'].downcase == "active"
						redeemed = false
					else
						redeemed = true
					end
					ds = ds.where(:redeemed => redeemed)
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(:serial_no, query_string)}
				end
			end
		end

		if from_date and to_date
			ds = ds.where(:created_at => from_date..to_date)
		end

		total = ds.count

		ds = ds.paginate(page, limit)

		recs = ds.collect do |rec|
			product = Product.where(id: rec.product_id).first

			{
				id: rec.id,
				material: rec.material,
				serial_no: rec.serial_no,
				status: rec.redeemed,
				points: rec.product[:points],
				created_at: rec.created_at.iso8601,
			}
		end

		return recs, total
	end

	def upload_coupons params

		excel_file = params[:file][:tempfile]
		ret = nil

		workbook = Roo::Spreadsheet.open excel_file
		firstsheet = workbook.sheet(0)

		DB.transaction do

			coupon_added = coupon_skipped = coupon_rejected = 0
			skipped_coupon = []
			rejected_coupon = []

			firstsheet.each_with_index(
				material: 'Material',
				serial_number: 'Serial Number',
				# points: 'Points',
			) do |row, ind|
				next if ind < 1

				material = row[:material].to_s
				serial_number = row[:serial_number].to_s
				# points = row[:points].to_s

				if material.to_s.empty?
					coupon_rejected += 1
					rejected_coupon.push serial_number + ' - Material not present'
					next
				end
				if ((serial_number.scan(/^\d+$/).any?)) and serial_number.length == 16
					sl_num = "00#{serial_number}"
				else
					coupon_rejected += 1
					rejected_coupon.push serial_number + ' - Invalid serial number'
					next
				end

				product = Product.where(material: material).first
				coupon_exist = Coupon.where(serial_no: sl_num).first

				if !product
					coupon_rejected += 1
					rejected_coupon.push material.to_s + " - Material doesn't exist"
					next
				end

				if coupon_exist
					coupon_skipped += 1
					skipped_coupon.push serial_number.to_s + " - Coupon already exist"
					next
				end

				coupon_added +=1

				Coupon.create(
					material: material,
					serial_no: sl_num,
					product_id: product.id
				)
			end

			ret = {
				created: coupon_added,
				skipped: coupon_skipped,
				rejected: coupon_rejected,
				records_rejected: rejected_coupon,
				records_skipped: skipped_coupon,
			}

			ret
		end
	end

	def upload_points_verify recs

		invalids = []

		recs.each do |rec|

			mobile = rec[:mobile]
			points = rec[:points].to_i
			type = rec[:type]

			mobile = "91#{mobile}" if mobile.length == 10
			participant = Participant.where(mobile: mobile, active: true).first

			if participant
				user_role = Permission.where(user_id: participant.id).first

				if points > 0
					if !user_role.role_name.include? 'rsa'
						invalids.push code + ' - Invalid User'
					end
				elsif points < 0
					balance = participant.get_balance_points

					if balance.nil?
						invalids.push mobile + ' - Insufficient points to deduct'
					elsif balance < points.abs
						invalids.push mobile + ' - Insufficient points to deduct'
					end
				end
			else
				invalids.push mobile + ' - Invalid Mobile Number'
			end
		end
		invalids
	end

	def upload_points recs
		invalids = []
		arr = []

		DB.transaction do
			recs.each do |rec|

				mobile = rec[:mobile]
				points = rec[:points].to_i
				type = rec[:type]
				description = rec[:description]
				category = rec[:category]

				mobile = "91#{mobile}" if mobile.length == 10
				participant = Participant.where(mobile: mobile, active: true).first
				claim_code = SecureRandom.hex(4).upcase
				type = "upload points"

				if participant
					part_point = participant.point

					if points > 0
						participant.add_claim(
							code: claim_code,
							total_points: points,
							description: description,
							category: category,
							type: type
						)

						if part_point.nil?

							point_new = Point.new(
								user_id: participant.id,
								earned: points
							)
							point_new.save
						else
							total_points = (part_point.earned) + (points)
							part_point.update(earned: total_points)
						end

						send_sms_points_earned participant, points
					else
						participant.add_claim(
							code: claim_code,
							points_debited: points.abs,
							description: description,
							category: category,
							type: type
						)

						total_points = (part_point.earned) - (points.abs)
						part_point.update(earned: total_points)
					end
				else
					invalids.push code
				end
			end
		end

		invalids
	end

	def coupons_download filters
		ds = Coupon.dataset.not_deleted

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'status'
					if filter['value'].downcase == "active"
						redeemed = false
					else
						redeemed = true
					end
					ds = ds.where(:redeemed => redeemed)
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(:serial_no, query_string)}
				end
			end
		end

		if from_date and to_date
			ds = ds.where(:created_at => from_date..to_date)
		end

		recs = ds.collect do |rec|

			[
				rec.material,
				"=\"#{rec.serial_no}\"",
				rec.redeemed ? "Redeemed" : "Active",
				rec.created_at.iso8601,
			]
		end

		CSV.generate do |csv|
			csv << ['Material', 'Serial Number', 'Status', 'Date']
			recs.each { |row| csv << row }
		end
	end

	def get_orders  page, limit, filters, sorter
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = Order.dataset

		from_date = nil
		to_date = nil
		if filters
			filters.each do |filter|
				if filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'status'
					query_string = "#{filter['value'].to_s.downcase}%"
					ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
				elsif filter['property'] == 'query'
					query_string = "#{filter['value'].to_s.upcase}%"
					ds = ds.where{Sequel.ilike(Sequel[:orders][:name], query_string) | Sequel.ilike(Sequel.function(:lower, :mobile), query_string.downcase)}
				end
			end
		end

		if from_date and to_date
			ds = ds.where(created_at: from_date..to_date)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count

		ds = ds.paginate(page, limit)

		recs = ds.collect do |order|
			items = order.items.collect do |orderitem|
				{
					quantity: orderitem.quantity,
					suborder_number: orderitem.suborder_number,
					status: orderitem.status,
					name: orderitem.name,
					model_number: orderitem.model_number,
					code: orderitem.code,
					brand: orderitem.brand,
					description: orderitem.description,
					image: "/images/rewards/products/pics/#{orderitem.image}",
					thumbnail: "/images/rewards/products/thumbs/#{orderitem.thumbnail}",
					points: orderitem.points
				}
			end

			{
				id: order.id,
				order_number: order.order_number,
				points: order.points,
				num_items: order.num_items,
				date: order.created_at.iso8601,
				name: order.name,
				mobile: order.mobile,
				email: order.email,
				address1: order.address1,
				address2: order.address2,
				district: order.district,
				city: order.city,
				state: order.state,
				pincode: order.pincode,
				items: items
			}
		end

		return recs, total
	end

	def update_order params, order

		suborders = JSON.parse params[:sub_orders]

		user = DB[:users].where(id: order.user_id).first

		suborders.each do |orderitem|
			orderdetail = OrderItem.where(suborder_number: orderitem["suborder_number"]).first

			if orderitem["status"] == 'canceled'

				point = Point.where(user_id: order[:user_id]).first
				point.update(
					redeemed: point.redeemed - orderdetail.points*orderdetail.quantity
				)
			end
			orderdetail.update(status: orderitem["status"])
			orderdetail.save

			if user[:mobile]
				if orderdetail[:status] == 'dispatched'
					send_sms_helpdesk_status_dispatched user,orderdetail
				elsif orderdetail[:status] == 'delivered'
					send_sms_helpdesk_status_delivered user,orderdetail
				# elsif orderdetail[:status] == 'canceled'
				# 	send_sms_helpdesk_status_canceled user,orderdetail
				end
			end
		end


		order.values
	end

	def upload_banners params
		# DB.transaction do

			params.each do |k,v|

				if k.include? 'banner_one'
					fileptr = v[:tempfile]
					fileext = v[:type].split('/')[1]
					filename = "banner-1" + ".#{fileext}"
					file_save_as = "#{ENV['IMAGES_DIR']}/banners/#{filename}"


					dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))
					banner_jpeg = dir+'/banner-1.jpeg'
					banner_png =  dir+'/banner-1.png'

					if File.exist?(banner_jpeg)
						File.delete banner_jpeg
					elsif File.exist?(banner_png)
						File.delete banner_png
					end
					File.open(file_save_as, "wb") do |save_file|
						save_file.write(fileptr.read)
					end

				end

				if k.include? 'banner_two'
					fileptr = v[:tempfile]
					fileext = v[:type].split('/')[1]
					filename = "banner-2" + ".#{fileext}"
					file_save_as = "#{ENV['IMAGES_DIR']}/banners/#{filename}"

					dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))
					banner_jpeg = dir+'/banner-2.jpeg'
					banner_png =  dir+'/banner-2.png'

					if File.exist?(banner_jpeg)
						File.delete banner_jpeg
					elsif File.exist?(banner_png)
						File.delete banner_png
					end

					File.open(file_save_as, "wb") do |save_file|
						save_file.write(fileptr.read)
					end

				end


				if k.include? 'banner_three'
					fileptr = v[:tempfile]
					fileext = v[:type].split('/')[1]
					filename = "banner-3" + ".#{fileext}"
					file_save_as = "#{ENV['IMAGES_DIR']}/banners/#{filename}"

					dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))
					banner_jpeg = dir+'/banner-3.jpeg'
					banner_png =  dir+'/banner-3.png'

					if File.exist?(banner_jpeg)
						File.delete banner_jpeg
					elsif File.exist?(banner_png)
						File.delete banner_png
					end

					File.open(file_save_as, "wb") do |save_file|
						save_file.write(fileptr.read)
					end


				end

				if k.include? 'banner_four'
					fileptr = v[:tempfile]
					fileext = v[:type].split('/')[1]
					filename = "banner-4" + ".#{fileext}"
					file_save_as = "#{ENV['IMAGES_DIR']}/banners/#{filename}"

					dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))
					banner_jpeg = dir+'/banner-4.jpeg'
					banner_png =  dir+'/banner-4.png'

					if File.exist?(banner_jpeg)
						File.delete banner_jpeg
					elsif File.exist?(banner_png)
						File.delete banner_png
					end

					File.open(file_save_as, "wb") do |save_file|
						save_file.write(fileptr.read)
					end

				end

			# end
		end
	end

	def get_banners
		dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))

		entries = Dir.entries dir

		ret = []

		entries.each do |file|
			next if File.directory? file

			ret.push({
				name: file,
				image_url: "#{ENV['IMAGE_BASE_URL']}/images/banners/#{file}?#{Time.now.to_i}"
			})
		end
		ret

	end

	def delete_banners params

		dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))

		entries = Dir.entries dir

		entries.each do |file|
			filename = file.split('.')[0]
			ext = file.split('.')[1]

			params.each do |k,v|
				if k.include? 'banner_one'
					if filename == 'banner-1'
						file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners/banner-1'+ ".#{ext}"))
						File.delete(file) if File.exist?(file)
					end
				end

				if k.include? 'banner_two'
					if filename == 'banner-2'
						file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners/banner-2'+ ".#{ext}"))
						File.delete file
					end
				end

				if k.include? 'banner_three'
					if filename == 'banner-3'
						file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners/banner-3'+ ".#{ext}"))
						File.delete file
					end
				end

				if k.include? 'banner_four'
					if filename == 'banner-4'
						file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners/banner-4'+ ".#{ext}"))
						File.delete file
					end
				end
			end

		end
	end

	def add_lne_topic  params, data

		month = data[:month].to_s.empty? ? params[:month] : data[:month]
		year = data[:year].to_s.empty? ? params[:year] : data[:year]
		topic = data[:topic].to_s.empty? ? params[:topic] : data[:topic]
		description = data[:description].to_s.empty? ? params[:description] : data[:description]

		raise "Month required" if month.to_s.empty?
		raise "Year is required" if year.to_s.empty?
		raise "Topic is required" if topic.to_s.empty?

		today = Date.today
		d = Date.new(year.to_i,month.to_i)

		if today.month > 3
			year_start = Date.new(today.year,4)
			year_end = Date.new(today.year,3,31).next_year()
		else
			year_start = Date.new(today.year,4).prev_year()
			year_end = Date.new(today.year,3,31)
		end

		raise "Add Topic for current financial year" if (d < year_start) or (d > year_end)

		exist = Topic.where(month: month, year: year).first
		raise "Topic for #{d.strftime('%B %Y')} already exist" if exist

		attachments = Array(params[:attachments])

		DB.transaction do
			topic = Topic.create(
				month: month,
				year: year,
				topic: topic,
				description: description,
				video_id: params[:video_id]
			)

			i=1
			params.each do |k,v|
				if k.include? 'attachment_'
					if i<=5
						fileptr = v[:tempfile]
						fileext = v[:filename].split('.')[1]
						filetype = v[:type].split('/')[1]
						# filename = topic[:topic].downcase + rand(00..11).to_s + '-a' + ".#{fileext}"
						name = v[:filename]
						filename = name.gsub(' ', '_')

						file_save_as = "#{ENV['UPLOADS_DIR']}/attachments/#{filename}"

						File.open(file_save_as, "wb") do |save_file|
							save_file.write(fileptr.read)
						end

						file_link = "#{ENV['UPLOADS_DIR']}/attachments/#{filename}"

						topic.add_attachment(
							name: filename,
							type: filetype,
						)
						i=i+1;
						topic.save
					end
				end
			end

			topic.values
		end
	end

	def add_levels_title  params, data

		level = data[:level].to_s.empty? ? params[:level] : data[:level]
		title = data[:title].to_s.empty? ? params[:title] : data[:title]
		description = data[:description].to_s.empty? ? params[:description] : data[:description]

		if level.to_i == 1
			points = 200
		elsif level.to_i == 2
			points = 300
		elsif level.to_i == 3
			points = 500
		elsif level.to_i == 4
			points = 1000
		end

		raise "level required" if level.to_s.empty?
		raise "title is required" if title.to_s.empty?
		raise "description is required" if description.to_s.empty?

		DB.transaction do
			levels = Level.create(
				level: level,
				title: title,
				points: points,
				description: description,
				published: false
			)

			i=1

			params.sort.each do |k,v|
					if k.include? 'material_'
						if i<=10
							break if i == 11
							if !v.respond_to?(:to_str)
								fileptr = v[:tempfile]
								fileext = v[:filename].split('.')[1]
								filetype = v[:type].split('/')[1]
								name = v[:filename]
								filename = name.gsub(' ', '_')
								# filename = filename.split(',')[0]
								file_save_as = "#{ENV['UPLOADS_DIR']}/materials/#{filename}"

								File.open(file_save_as, "wb") do |save_file|
									save_file.write(fileptr.read)
								end
							else v.respond_to?(:to_str)
								filename = v
								filetype = 'video'
							end


							levels.add_material(
								material: filename,
								material_type: filetype,
								material_number: i
							)
							i=i+1;
							levels.save

						end
					end
			end

			levels.values
		end
	end

	def update_levels_title params, level_title


		title = params[:title].to_s.empty? ? level_title[:title] : params[:title]
		description = params[:description].to_s.empty? ? level_title[:description] : params[:description]
		saved_materials = JSON.parse params[:saved_materials]

		materialids = []
		saved_materials.each do |rec|
			materialids.push(rec["id"])
		end

		level_title.material_dataset.exclude(:id => materialids).delete

		DB.transaction do
			level_title.update(
				title: title,
				description: description
			)

			raise level_title.errors.full_messages.join(', ') if !level_title.valid?
			i= materialids.length
				params.each do |k,v|
					if k.include? 'material_'
						if i<=10
							break if i == 11
							if !v.respond_to?(:to_str)
								fileptr = v[:tempfile]
								fileext = v[:filename].split('.')[1]
								filetype = v[:type].split('/')[1]
								name = v[:filename]
								filename = name.gsub(' ', '_')
								# filename = filename.split(',')[0]
								file_save_as = "#{ENV['UPLOADS_DIR']}/materials/#{filename}"

								File.open(file_save_as, "wb") do |save_file|
									save_file.write(fileptr.read)
								end
							else v.respond_to?(:to_str)
								filename = v
								filetype = 'video'
							end


							level_title.add_material(
								material: filename,
								material_type: filetype,
								material_number: i
							)
							i=i+1;
							level_title.save
						end
					end
			end
		end

		materials = get_all_materials(level_title)
		{
			level_title_id: level_title.id,
			level: level_title.level,
			title: level_title.title,
			description: level_title.description,
			published: level_title.published,
			materials:materials
		}

	end

	def add_levels_question level_title, data

		raise "Maximum number of questions reached" if level_title.levelquestions.count > 50

		data[:rec].each do |rec|

			raise "Question answer is required" if rec[:question].to_s.empty?
			raise "Correct answer is required" if rec[:correct].to_s.empty?

			DB.transaction do
				question = level_title.add_levelquestion(
					question: rec[:question],
					correct: rec[:correct]
				)

				rec[:answers].each do |opt|
					raise "Minimum two option is required" if (opt[:option_0].to_s.empty?) or (opt[:option_1].to_s.empty?)
					question.update(
						options: opt
					)
				end
			end

		end
	end

	def update_levels_question quest, data

		raise "Correct answer is required" if data[:correct].to_s.empty?

		que = data[:question].to_s.empty? ? quest[:question] : data[:question]
		correct = data[:correct].to_s.empty? ? quest[:correct] : data[:correct]

		DB.transaction do
			quest.update(
				question: que,
				correct: correct,
			)
			data[:answers].each do |opt|
				raise "Minimum two option is required" if (opt[:option_0].to_s.empty?) or (opt[:option_1].to_s.empty?)
				quest.update(
					options: opt
				)
			end
			question = quest
			{
				id: question.id,
				question: question.question,
				correct: question.correct,
				options: question.options
			}
		end
	end

	def get_all_titles level, page, limit, filters
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = Level.dataset.where(:level => level)

		if filters
			filters.each do |filter|
				if filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.ilike(Sequel[:levels][:title], query_string)}
				end
			end
		end

		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rec|

			attachments = self.get_all_materials(rec)
			{
				created_at:rec.created_at,
				level_title_id: rec.id,
				level: rec.level,
				title: rec.title,
				description: rec.description,
				published: rec.published,
				published_date: rec.published_date,
				# attempted: rec.attempted,
				questions: rec.levelquestions_dataset.not_deleted.count,
				materials: attachments
			}
		end

		return recs, total
	end

	def get_all_materials rec

		rec.material_dataset.collect do |att|
			video_id = nil
			if att.material_type == "video"
				video_id = att.material.to_i
			else
				link = "#{ENV['IMAGE_BASE_URL']}/uploads/materials/#{att.material}"
			end
			{
				id: att.id,
				name: att.material,
				type: att.material_type,
				link: link.nil? ? nil: link,
				video_id: video_id.nil? ? nil:"https://player.vimeo.com/video/"+video_id.to_s
			}
		end
	end

	def get_all_topics page, limit, filters
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = Topic.dataset.not_deleted
		if filters
			filters.each do |filter|
				if filter['property'].downcase == "month"
					ds = ds.where(month: filter['value'].to_i)
				elsif filter['property'].downcase == 'year'
					ds = ds.where(year: filter['value'].to_i)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.ilike(Sequel[:topics][:topic], query_string)}
				end
			end
		end

		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rec|
			attachments = self.get_all_attachments(rec)
			{
				id: rec.id,
				month: rec.month,
				year: rec.year,
				topic: rec.topic,
				published: rec.published,
				attempted: rec.attempted,
				video_id: rec.video_id,
				description: rec.description,
				questions: rec.questions_dataset.not_deleted.count,
				attachments: attachments
			}
		end

		return recs, total
	end

	def get_all_attachments rec

		rec.attachments_dataset.collect do |att|
			{
				id: att.id,
				name: att.name,
				type: att.type,
				link: "#{ENV['IMAGE_BASE_URL']}/uploads/attachments/#{att.name}"
			}
		end
	end

	def update_topic params, topic

		month = params[:month].to_s.empty? ? topic[:month] : params[:month]
		year = params[:year].to_s.empty? ? topic[:year] : params[:year]
		topic_name = params[:topic].to_s.empty? ? topic[:topic] : params[:topic]
		description = params[:description].to_s.empty? ? topic[:description] : params[:description]
		video_id = params[:video_id].to_s.empty? ? topic[:video_id] : params[:video_id]
		saved_attachments=JSON.parse params[:save_attachments]
		attchids=[]
		saved_attachments.each do |rec|
			attchids.push(rec["id"])
		end

		topic.attachments_dataset.exclude(:id => attchids).delete

		today = Date.today
		d = Date.new(year.to_i,month.to_i)

		if today.month > 3
			year_start = Date.new(today.year,4)
			year_end = Date.new(today.year,3,31).next_year()
		else
			year_start = Date.new(today.year,4).prev_year()
			year_end = Date.new(today.year,3,31)
		end

		raise "Add Topic for current financial year" if (d < year_start) or (d > year_end)



		d = Date.new(year.to_i,month.to_i)
		exist = Topic.where(month: params[:month], year: params[:year]).exclude(id: topic.id).first
		raise "Topic for #{d.strftime('%B %Y')} already exist" if exist

		DB.transaction do
			topic.update(
				month: month,
				year: year,
				topic: topic_name,
				video_id: video_id,
				description: description,
			)

			raise topic.errors.full_messages.join(', ') if !topic.valid?
			i= attchids.length
			params.each do |k,v|
				if k.include? 'attachment_'
					if i<5
						fileptr = v[:tempfile]
						fileext = v[:filename].split('.')[1]
						filetype = v[:type].split('/')[1]
						filename = v[:filename]
						# file_save_as = "#{ENV['ATTCH_DIR']}/#{filename}"
						file_save_as = "#{ENV['UPLOADS_DIR']}/attachments/#{filename}"

						File.open(file_save_as, "wb") do |save_file|
							save_file.write(fileptr.read)
						end

						file_link ="#{ENV['UPLOADS_DIR']}/attachments/#{filename}"
						# file_link = "#{ENV['ATTCH_DIR']}/#{filename}"

						topic.add_attachment(
							name: filename,
							type: filetype,
						)
						i=i+1;
						topic.save
					end
				end
			end
		end

		attachment = get_all_attachments(topic)
		{
			id: topic.id,
			month: topic.month,
			year: topic.year,
			topic: topic.topic,
			attachment: attachment,
			published: topic.published
		}

	end

	def delete_topic topic
		topic.soft_delete
		true
	end

	def delete_question question
		question.soft_delete
		true
	end

	def level_delete_question question
		question.soft_delete
		true
	end

	def add_lne_question topic, data

		raise "Maximum number of questions reached" if topic.questions.count > 50

		data[:rec].each do |rec|
			raise "Question answer is required" if rec[:question].to_s.empty?
			raise "Correct answer is required" if rec[:correct].to_s.empty?
			DB.transaction do
				question = topic.add_question(
					question: rec[:question],
					correct: rec[:correct],
				)

				rec[:answers].each do |opt|
					raise "Minimum two option is required" if (opt[:option_0].to_s.empty?) or (opt[:option_1].to_s.empty?)
					question.update(
						options: opt
					)
				end
			end

		end
	end

	def update_lne_question quest, data

		raise "Correct answer is required" if data[:correct].to_s.empty?

		que = data[:question].to_s.empty? ? quest[:question] : data[:question]
		correct = data[:correct].to_s.empty? ? quest[:correct] : data[:correct]

		DB.transaction do
			quest.update(
				question: que,
				correct: correct,
			)
			data[:answers].each do |opt|
				raise "Minimum two option is required" if (opt[:option_0].to_s.empty?) or (opt[:option_1].to_s.empty?)
				quest.update(
					options: opt
				)
			end
			question = quest
			{
				id: question.id,
				question: question.question,
				correct: question.correct,
				options: question.options
			}
		end
	end

	def publish_topic topic, data

		raise "Need at least one Question to publish" if topic.questions.count < 1
		DB.transaction do
			topic.update(published: data[:publish])
		end
	end

	def publish_level_title level_title, data

		published_level = Level.where(:level => level_title.level,:published => true).first
		prev_unpublished_level = Level.where(:level => level_title.level,:published => false).last

		raise "You cannot publish more than one title in a level" if published_level && data[:publish]
		raise "Need at least one Question to publish" if level_title.levelquestions.count < 1

		ds = Participant.dataset
		users_ds = ds.join(:permissions,:user_id => Sequel[:users][:id],:role_name => 'rsa')

		level_response_ds = ds.join(:levels_quizresponse,:user_id => Sequel[:users][:id],:completed => true,:level_title_id => level_title.id)
		level_unattempted_ds = ds.join(:levels_quizresponse,:user_id => Sequel[:users][:id],:attempted => false,:level_title_id => level_title.id)
		level_attempted_ds = ds.join(:levels_quizresponse,:user_id => Sequel[:users][:id],:attempted => true,:completed => false,:level_title_id => level_title.id)

		if level_title.published_date
			if prev_unpublished_level
				newuser_ds = Participant.dataset.where(Sequel[:users][:created_at] => prev_unpublished_level.unpublished_date..Time.now)
				if newuser_ds.count > 0
					newuser_ds = newuser_ds.join(:permissions,:user_id => Sequel[:users][:id],:role_name => 'rsa')
					newuser_response_ds = newuser_ds.join(:levels_quizresponse,:user_id => Sequel[:users][:id],:completed => true,:level_title_id => level_title.id)
					newuser_unattempted_ds = newuser_ds.join(:levels_quizresponse,:user_id => Sequel[:users][:id],:attempted => false,:level_title_id => level_title.id)

					raise "Can't Unpublish,all the new users have not completed this level" if newuser_ds.count != newuser_response_ds.count and !data[:publish] or newuser_unattempted_ds.count > 0 and !data[:publish]

				end
			else
				if level_response_ds.count > 0
					raise "Can't Unpublish,all the users have not completed this level" if users_ds.count != level_response_ds.count and !data[:publish] or level_unattempted_ds.count > 0 and !data[:publish]
				elsif level_attempted_ds.count > 0 and !data[:publish]
					raise "Can't Unpublish,all the users have not completed this level"
				end
			end
		else
			if level_response_ds.count > 0
				raise "Can't Unpublish,all the users have not completed this level" if users_ds.count != level_response_ds.count and !data[:publish] or level_unattempted_ds.count > 0 and !data[:publish]
			end
		end



		Levelquizresponse.where(:level_title_id => level_title[:id],:deleted_at => nil).exclude(:response => nil).each do |rec|
			if !rec[:completed] and rec[:pending]
				raise "Can't Unpublish.Some of the users are under process"
			elsif !rec[:completed] and !rec[:pending]
				raise "Can't Unpublish.Some of the users are under process"
			end
		end


		DB.transaction do
			level_title.update(
				published: data[:publish],
				published_date:Time.now
			)

			if published_level
				published_level.update(
					published: data[:publish],
					unpublished_date: Time.now
				)
			end
		end
	end


	# * ============================================================================= #
	# *  - - - - - - Common Module - - - - - -   #
	# * ============================================================================= #

	def get_participants start, page, limit, filters, sorter
		raise 'start is required' if start.nil?
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?


		ds = Address.dataset.distinct.select(Sequel[:addresses][:user_id])
		ds = ds.join(:states, :id => :state_id)
		ds = ds.join(:cities, :id => Sequel[:addresses][:city_id])
		ds = ds.join(:users, :id => Sequel[:addresses][:user_id], Sequel[:users][:deleted_at] => nil, :role => 'p')
		ds = ds.select(Sequel[:addresses][:user_id]).distinct
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id], :role_name => ['dl','rsa'])

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'role'
					ds = ds.where(Sequel[:permissions][:role_name] => filter['value'].downcase)
				elsif filter['property'] == 'state'
					ds = ds.where(Sequel[:addresses][:state_id] => filter['value'])
				elsif filter['property'] == 'city'
					ds = ds.where(Sequel[:addresses][:city_id] => filter['value'])
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'active'
					ds = ds.where(Sequel[:users][:active] => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.ilike(Sequel[:users][:name], query_string) }
				end
			end
		end

		if from_date and to_date
			ds = ds.where(Sequel[:users][:created_at] => from_date..to_date)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count
		recs = []
		ds.drop(start).each_with_index do |rec, ind|
			break if ind > limit
			recs.push self.get_participant_detail rec.participant
		end
		return recs, total

	end

	def users_download filters
		ds = Address.dataset.distinct.select(Sequel[:addresses][:user_id])
		ds = ds.join(:states, :id => :state_id)
		ds = ds.join(:cities, :id => Sequel[:addresses][:city_id])
		ds = ds.join(:users, :id => Sequel[:addresses][:user_id], Sequel[:users][:deleted_at] => nil, :role => 'p')
		ds = ds.select(Sequel[:addresses][:user_id]).distinct
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id], :role_name => ['dl','rsa'])



		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'role'
					ds = ds.where(Sequel[:permissions][:role_name] => filter['value'].downcase)
				elsif filter['property'] == 'state'
					ds = ds.where(Sequel[:addresses][:state_id] => filter['value'])
				elsif filter['property'] == 'city'
					ds = ds.where(Sequel[:addresses][:city_id] => filter['value'])
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.like(Sequel[:users][:name], query_string) }
				end
			end
		end

		if from_date and to_date
			ds = ds.where(Sequel[:users][:created_at] => from_date..to_date)
		end

		recs = ds.collect do |rec|
			self.get_participant_detail rec.participant
		end
		users = []
		recs.each do |item|
			item[:mobile][0..1] = ''
			users.push(
				[
					item[:name],
					"=\"#{item[:mobile]}\"",
					item[:email],
					item[:participant_type],
					item[:created_at],
					item[:address1],
					item[:address2],
					item[:city_name],
					item[:state_name],
					item[:pincode],
					item[:dob],
					item[:doa],
					item[:doj],
					item[:store_name],
					item[:experience],
					item[:qualification],
					item[:mother_tongue]
				]
			)
		end

		CSV.generate do |csv|
			csv << ['Name', 'Mobile', 'Email', 'Participant Type', 'Date', 'Address1', 'Address2', 'City', 'State', 'Pincode', 'DOB', 'DOA','DOJ', 'Store Name', 'Total Experience', 'Education Qualification', 'Mother Tongue' ]
			users.each { |row| csv << row }
		end
	end

	def update_participant_details data, participant

		DB.transaction do
			if data[:name] or data[:email] or data[:tier] or data[:parent_id]
				name = data[:name].to_s.empty? ? participant.name : data[:name]
				email = data[:email].to_s.empty? ? participant.email : data[:email]
				parent_id = data[:parent_id].to_s.empty? ? participant.parent_id : data[:parent_id]

				participant.update(
					name: name,
					email: email,
					parent_id: parent_id
				)
			end

			if participant.detail
				doa = data[:doa].to_s.empty? ? participant.detail.doa : data[:doa]
				dob = data[:dob].to_s.empty? ? participant.detail.dob : data[:dob]
				doj = data[:doj].to_s.empty? ? participant.detail.doj : data[:doj]
				store_name = data[:store_name].to_s.empty? ? participant.detail.store_name : data[:store_name]
				experience = data[:experience].to_s.empty? ? participant.detail.experience : data[:experience]
				qualification = data[:qualification].to_s.empty? ? participant.detail.qualification : data[:qualification]
				mother_tongue = data[:mother_tongue].to_s.empty? ? participant.detail.mother_tongue : data[:mother_tongue]

				participant.detail_dataset.update(
					doa: doa,
					dob: dob,
					doj: doj,
					store_name: store_name,
					experience: experience,
					qualification: qualification,
					mother_tongue: mother_tongue

				)
				participant.reload
			else
				ParticipantDetail.create(
					doa: data[:doa],
					dob: data[:dob],
					doj: data[:doj],
					store_name: data[:store_name],
					experience: data[:experience],
					qualification: data[:qualification],
					mother_tongue: data[:mother_tongue],
					user_id: participant.id
				)
				participant.reload
			end

			if data[:address1] or data[:address2] or data[:address3]or data[:district] or data[:pincode] or data[:city_id]
				address = participant.addresses.first

				address1 = data[:address1].to_s.empty? ? address[:address1] : data[:address1]
				address2 = data[:address2].to_s.empty? ? address[:address2] : data[:address2]
				address3 = data[:address3].to_s.empty? ? address[:address3] : data[:address3]
				pincode = data[:pincode].to_s.empty? ? address[:pincode] : data[:pincode]
				city_id = data[:city_id].to_s.empty? ? address[:city_id] : data[:city_id]
				district = data[:district].to_s.empty? ? address[:district] : data[:district]

				city = City[city_id.to_i]
				raise 'Invalid city' if !city

				address.update(
					address1: address1,
					address2: address2,
					address3: address3,
					pincode: pincode,
					city_id: city_id,
					district: district,
					state_id: city.state.id
				)
			end


		end

		self.get_participant_detail participant
	end

	def get_participant_detail participant

		if participant.detail
			dob = participant.detail.dob.nil? ? nil : participant.detail.dob
			doa = participant.detail.doa.nil? ? nil : participant.detail.doa
			doj = participant.detail.doj.nil? ? nil : participant.detail.doj
			store_name = participant.detail.store_name.nil? ? nil : participant.detail.store_name
			experience = participant.detail.experience.nil? ? nil : participant.detail.experience
			qualification = participant.detail.qualification.nil? ? nil : participant.detail.qualification
			mother_tongue = participant.detail.mother_tongue.nil? ? nil : participant.detail.mother_tongue

			if !dob.nil?
				# Total seconds in a year
				sec = 31557600
				age = ((Time.now - dob.to_time) / sec).floor
			end

		end

		role = participant.permission.role_name

		address = participant.addresses.first
		parent_details = Participant.where(id: participant.parent_id).first

		helpdesk_request = HelpDeskRequest.deleted.where(mobile: participant.mobile).first
		if helpdesk_request
			referred_by = helpdesk_request.referred_by
		end

		if parent_details
			parent_mobile = parent_details.mobile
			parent_name = parent_details.name
		end

		if parent_details
			if parent_details.permission.role_name == 'dl'
				mapped_dealer_name = parent_details.name
				mapped_dealer_mobile = parent_details.mobile
			elsif parent_details.permission.role_name == 'cso'
				mapped_cso_name = parent_details.name
				mapped_cso_mobile = parent_details.mobile
			end
		end



		{
			id: participant.id,
			created_at: participant.created_at,
			name: participant.name,
			parent_id: participant.parent_id,
			parent_mobile: parent_mobile,
			parent_name: parent_name,
			mobile: participant.mobile,
			email: participant.email,
			participant_type: role.capitalize ,
			active: participant.active,
			address1: address.address1,
			address2: address.address2,
			address3: address.address3,
			city_id: address.city_id,
			city_name: address.city.name,
			state_id: address.state_id,
			state_name: address.state.name,
			pincode: address.pincode,
			doa: doa,
			dob: dob,
			doj: doj,
			age: age,
			store_name: store_name,
			experience: experience,
			qualification: qualification,
			mother_tongue: mother_tongue,
			referred_by: referred_by,
			mapped_dealer_name: mapped_dealer_name,
			mapped_dealer_mobile: mapped_dealer_mobile,
			mapped_cso_name: mapped_cso_name,
			mapped_cso_mobile: mapped_cso_mobile

		}
	end

	def update_participant_status data, participant
		participant.update( active: data[:active] )
	end

	def get_participant_earnhistory participant, start, limit, filters, sorter ,type
		participant.earnpoints_history start, limit, filters, sorter, type
	end

	def get_participant_redeemhistory participant, start, page, limit, filters, sorter
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?
		ds = participant.orders_dataset.not_deleted

		from_date = nil
		to_date = nil
		if filters
			filters.each do |filter|
				if filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24*60*60)
				# elsif filter['property'] == 'status'
				# 	query_string = "#{filter['value'].to_s.downcase}%"
				# 	ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
				else
					query_string = "#{filter['value'].to_s.upcase}%"
					ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
				end
			end
		end

		if from_date and to_date
			ds = ds.where(created_at: from_date..to_date)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count

		ds = ds.paginate(page, limit)

		recs = ds.collect do |order|
			items = order.items.collect do |orderitem|

				{
					quantity: orderitem.quantity,
					name: orderitem.name,
					model_number: orderitem.model_number,
					code: orderitem.code,
					brand: orderitem.brand,
					description: orderitem.description,
					image:  "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{orderitem.image}",
					thumbnail:  "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{orderitem.thumbnail}",
					# image: $image_base_url + 'images/rewards/products/pics/' + orderitem.image,
					# # image: $image_base_url + orderitem.image,
					# thumbnail: $image_base_url + 'images/rewards/products/thumbs/' + orderitem.thumbnail,
					# # thumbnail: $image_base_url + orderitem.thumbnail,
					points: orderitem.points
				}
			end

			{
				id: order.id,
				order_number: order.order_number,
				points: order.points,
				num_items: order.num_items,
				date: order.created_at.iso8601,
				name: order.name,
				mobile: order.mobile,
				address1: order.address1,
				address2: order.address2,
				district: order.district,
				# district: order.district,
				city: order.city,
				state: order.state,
				pincode: order.pincode,
				items: items
			}
		end

		return recs, total

	end

	def get_categories participant, continue_shopping
		if !continue_shopping
			DB.transaction do
				self.cartitems_dataset.not_deleted.where(participant_id: participant.id).each do |cartitem|
					cartitem.soft_delete
				end
			end
		end

		categories = Category.collect do |category|
			{
				id: category.id,
				name: category.name,
				image: "#{ENV['IMAGE_BASE_URL']}/images/rewards/categories/#{category.image}?#{Time.now.to_i}"
			}
		end
		categories
	end

	def add_category params
		raise 'category name is required' if !params[:category_name]

		category = Category.where(Sequel.function(:lower, :name) => params[:category_name].downcase).first
		all_subcategories = []

		DB.transaction do
			if category
				raise "category #{params[:category_name]} has already been added"
			else
				category = Category.create(name: params[:category_name].split.map(&:capitalize).join(' '))
				subcategories = JSON.parse params[:subcategories]

				if !subcategories.empty?
					subcategories.each do |sub_category|
						if SubCategory.where(Sequel.function(:lower, :name) => sub_category).first
							next
						else
							category.add_subcategory(name: sub_category.split.map(&:capitalize).join(' '))
						end
					end
				end
			end

			category.subcategories.each do |s|
				all_subcategories.push s.values
			end

			if params[:category_pic] and params[:category_pic][:tempfile]
				fileptr = params[:category_pic][:tempfile]
				fileext = params[:category_pic][:type].split('/')[1]
				filename = category[:name].downcase.tr(" ", "-") + ".#{fileext}"

				file_save_as = "#{ENV['IMAGES_DIR']}/rewards/categories/#{filename}"

				File.open(file_save_as, "wb") do |save_file|
					save_file.write(fileptr.read)
				end

				file_link = "#{ENV['IMAGES_DIR']}/rewards/categories/#{filename}"

				category.update(image: filename);
				category.save
			end
		end

		{
			category: category.values,
			subcategories: all_subcategories
		}
	end

	def update_category category, params

		all_subcategories = []
		DB.transaction do
			if params[:category_name]
				category.update(name: params[:category_name].split.map(&:capitalize).join(' '))
				category.save
			end

			subcategories = JSON.parse params[:subcategories]

			if !subcategories.empty?
				subcategories.each do |sub_category|
					if !sub_category["id"].to_s.empty?
						subcategory = SubCategory.where(id: sub_category["id"]).first
						subcategory.update(name: sub_category["name"].split.map(&:capitalize).join(' '))
					else
						category.add_subcategory(name: sub_category["name"].split.map(&:capitalize).join(' '))
					end
				end
			end

			category.subcategories.each do |s|
				all_subcategories.push s.values
			end

			if params[:category_pic] and params[:category_pic][:tempfile]
				fileptr = params[:category_pic][:tempfile]
				fileext = params[:category_pic][:type].split('/')[1]
				filename = category[:name].downcase.tr(" ", "-") + ".#{fileext}"

				file_save_as = "#{ENV['IMAGES_DIR']}/rewards/categories/#{filename}"

				File.open(file_save_as, "wb") do |save_file|
					save_file.write(fileptr.read)
				end

				file_link = "#{ENV['IMAGES_DIR']}/rewards/categories/#{filename}"

				category.update(image: filename)
				category.save
			end
		end

		{
			category: category.values,
			subcategories: all_subcategories
		}
	end

	def delete_category category
		raise "Cannot delete category. Category contains reward items" if !category.rewards.empty?

		category.delete
		true
	end

	def delete_subcategory subcategory
		raise "Cannot delete Sub Category. Sub Category contains reward items" if !subcategory.rewards.empty?

		subcategory.delete
		true
	end

	def get_all_categories
		ret = Category.dataset.collect do |category|
			subcategories = []

			sub_categories = category.subcategories

			if sub_categories
				sub_categories.each do |subcategory|
					subcategories.push(
						id: subcategory.id,
						name: subcategory.name,
						rewards_count: subcategory.rewards.count
					)
				end
			end

			{
				id: category.id,
				name: category.name,
				image: "#{ENV['IMAGE_BASE_URL']}/images/rewards/categories/#{category.image}?#{Time.now.to_i}",
				rewards_count: category.rewards.count,
				subcategories: subcategories
			}
		end
	end

	def get_reward_by_category category
		subcategories = []
		points = []
		brands = []
		rewards = category.rewards_dataset.not_deleted.where(active: true).collect do |reward|
			sub_category = reward.sub_category
			if sub_category
				subcategories.push(
					id: sub_category.id,
					name: sub_category.name
				)
			end

			points.push reward.points

			brands.push reward.brand

			{
				id: reward.id,
				name: reward.name,
				model_number: reward.model_number,
				code: reward.code,
				brand: reward.brand,
				description: reward.description,
				image: reward.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{reward.image}",
				thumbnail: reward.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{reward.thumbnail}",
				points: reward.points,
				category_id: reward.category_id,
				category_name: category.name,
				sub_category_id: reward.sub_category_id,
				sub_category_name: sub_category.nil? ? nil : sub_category.id
			}
		end

		return rewards, points.min, points.max, subcategories.uniq, brands.uniq
	end

	def upload_rewards params
		file = params[:file][:tempfile]
		ret = nil

		workbook = Roo::Spreadsheet.open file

		lastsheet = workbook.sheet(2)

		DB.transaction do
			rewards_rejected = 0
			rewards_rejected_no_code = 0
			rewards_updated = 0
			rewards_created = 0

			created_product_codes = []
			updated_product_codes = []
			rejected_product_codes = []

			lastsheet.each(
				subcategory_name: 'SubCategory Name',
				category_name: 'Category Name',
				name: 'Name',
				model_number: 'Model Number',
				code: 'Product Code',
				brand: 'Brand',
				description: 'Description',
				points: 'Points',
				status: 'Status'
			) do |h|

				next if h[:subcategory_name].nil? or h[:subcategory_name].to_s.empty?
				next if h[:subcategory_name] == 'SubCategory Name'

				subcategory_name = h[:subcategory_name].split(/(\W)/).map(&:capitalize).join
				category_name = h[:category_name].split(/(\W)/).map(&:capitalize).join
				name = h[:name]
				model_number = h[:model_number]
				code = h[:code]
				brand = h[:brand]
				description = h[:description]
				points = h[:points]
				status = h[:status].to_s.downcase

				if subcategory_name.to_s.empty? || category_name.to_s.empty? || name.to_s.empty?  || model_number.to_s.empty? || brand.to_s.empty? || description.to_s.empty? || points.to_s.empty?
					rewards_rejected += 1
					rejected_product_codes.push code.to_s + ' - Empty fields'
					next
				end

				if code.to_s.empty?
					rewards_rejected_no_code += 1
					next
				end
				active = false

				if status == 'active'
					active = true
				end
				subcategory = SubCategory.where(Sequel.function(:lower, :name) => subcategory_name.downcase).first

				if !subcategory
					rewards_rejected += 1
					rejected_product_codes.push code.to_s + ' - Invalid Sub Category'
					next
				else
					category = Category.where(id: subcategory[:category_id]).first

					reward = Reward.where(Sequel.function(:lower, :code) => code.downcase).first

					if reward
						rewards_updated += 1
						updated_product_codes.push code.to_s

						reward.update(
							category_id: category.id,
							sub_category_id: subcategory.id,
							name: name,
							model_number: model_number,
							code: code,
							brand: brand,
							description: description,
							active: active,
							points: points
						)
					else
						rewards_created += 1
						created_product_codes.push code.to_s

						reward = Reward.create(
							category_id: category.id,
							sub_category_id: subcategory.id,
							name: name,
							model_number: model_number,
							code: code,
							brand: brand,
							description: description,
							active: active,
							points: points
						)

						if !reward.valid?
							rewards_rejected += 1
							rejected_product_codes.push code.to_s + ' - Invalid Reward'
							next
						end

						reward.save

					end # * subcategory exists

				end # * roo
			end # * transaction

			ret = {
				rejected: rewards_rejected,
				updated: rewards_updated,
				created: rewards_created,
				rejected_product_codes: rejected_product_codes,
				updated_product_codes: updated_product_codes,
				created_product_codes: created_product_codes,
				rewards_rejected_no_code: rewards_rejected_no_code
			}
		end
		ret
	end

	def get_all_rewards page, limit, filters, sorter
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = Reward.dataset

		min_points = max_points = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'brand'
					ds = ds.where(Sequel.function(:lower, :brand) => filter['value'].downcase)
				elsif filter['property'] == 'active'
					ds = ds.where(:active => filter['value'])
				elsif filter['property'] == 'min_points'
					min_points = filter['value']
				elsif filter['property'] == 'max_points'
					max_points = filter['value']
				elsif filter['property'] == 'category_id'
					ds = ds.where(:category_id => filter['value'].to_i)
				elsif filter['property'] == 'sub_category_id'
					ds = ds.where(:sub_category_id => filter['value'].to_i)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.ilike(Sequel[:rewards][:name], query_string) | Sequel.ilike(Sequel[:rewards][:code], query_string)}
				end
			end
		end

		if min_points and max_points
			ds = ds.where(:points => min_points.to_i..max_points.to_i)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rec|
			{
				id: rec.id,
				name: rec.name,
				model_number: rec.model_number,
				code: rec.code,
				brand: rec.brand,
				description: rec.description,
				image: rec.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{rec.image}?#{Time.now.to_i}",
				thumbnail: rec.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{rec.thumbnail}?#{Time.now.to_i}",
				points: rec.points,
				category_id: rec.category_id,
				sub_category_id: rec.sub_category_id,
				active: rec.active
			}
		end
		return recs, total
	end

	def update_reward reward, params, data

		DB.transaction do

			if params[:points].to_i != reward[:points]
				existing_cartitem = CartItem.where(reward_id: reward[:id], Sequel[:cartitems][:deleted_at] => nil)
				existing_cartitem.delete if existing_cartitem
			end

			reward.set(
				name: params[:name].nil? ? reward[:name] : params[:name],
				model_number: params[:model_number].nil? ? reward[:model_number] : params[:model_number],
				brand: params[:brand].nil? ? reward[:brand] : params[:brand],
				description: params[:description].nil? ? reward[:description] : params[:description],
				points: params[:points].nil? ? reward[:points] : params[:points],
				category_id: params[:category_id].nil? ? reward[:category_id] : params[:category_id],
				sub_category_id:params[:sub_category_id].nil? ? reward[:sub_category_id] : params[:sub_category_id],
				active: params[:active].nil? ? reward[:active] : params[:active]
			)



			raise reward.errors.full_messages.join(', ') if !reward.valid?

			reward.save



			if params[:reward_thumbnail_pic] and params[:reward_thumbnail_pic][:tempfile]
				fileptr = params[:reward_thumbnail_pic][:tempfile]
				fileext = params[:reward_thumbnail_pic][:type].split('/')[1]
				filename = reward[:code].downcase + '-a' + ".#{fileext}"

				file_save_as = "#{ENV['IMAGES_DIR']}/rewards/products/thumbs/#{filename}"

				File.open(file_save_as, "wb") do |save_file|
					save_file.write(fileptr.read)
				end

				file_link = "#{ENV['IMAGES_DIR']}/rewards/products/thumbs/#{filename}"

				reward.update(thumbnail: filename)
				reward.save
			end

			if params[:reward_image_pic] and params[:reward_image_pic][:tempfile]
				fileptr = params[:reward_image_pic][:tempfile]
				fileext = params[:reward_image_pic][:type].split('/')[1]
				filename = reward[:code].downcase + '-b' + ".#{fileext}"

				file_save_as = "#{ENV['IMAGES_DIR']}/rewards/products/pics/#{filename}"

				File.open(file_save_as, "wb") do |save_file|
					save_file.write(fileptr.read)
				end

				file_link = "#{ENV['IMAGES_DIR']}/rewards/products/pics/#{filename}"

				reward.update(image: filename)
				reward.save
			end

			if data[:selected_thumbnail]
				if data[:selected_thumbnail].include? '?'
					thumbnail_file = data[:selected_thumbnail].split('?')[0]
				else
					thumbnail_file = data[:selected_thumbnail]
				end
				thumbnail_file = thumbnail_file.split('/').pop
				selected_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/uploads/gallery/products/thumbs/', thumbnail_file))

				selected_file_extension = selected_file.split('/').last.split('.').last

				updated_file_name = reward[:code].downcase + '-a.' + selected_file_extension

				update_file_path = ENV['IMAGES_DIR'] + '/rewards/products/thumbs/' + updated_file_name

				FileUtils.cp(selected_file,update_file_path)

				reward.update(thumbnail: updated_file_name)
				reward.save
			end

			if data[:selected_image]
				if data[:selected_image].include? '?'
					image_file = data[:selected_image].split('?')[0]
				else
					image_file = data[:selected_image]
				end
				image_file = image_file.split('/').pop
				selected_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/uploads/gallery/products/pics/', image_file))

				selected_file_extension = selected_file.split('/').last.split('.').last

				updated_file_name = reward[:code].downcase + '-b.' + selected_file_extension
				update_file_path = ENV['IMAGES_DIR'] + '/rewards/products/pics/' + updated_file_name

				FileUtils.cp(selected_file,update_file_path)

				reward.update(image: updated_file_name)
				reward.save
			end
		end

		{
			id: reward.id,
			name: reward.name,
			model_number: reward.model_number,
			code: reward.code,
			brand: reward.brand,
			description: reward.description,
			image: "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{reward.image}?#{Time.now.to_i}",
			thumbnail: "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{reward.thumbnail}?#{Time.now.to_i}",
			points: reward.points,
			category_id: reward.category_id,
			sub_category_id: reward.sub_category_id,
			active: reward.active
		}

	end

	def get_reward_brands
		brands = []
		ds = Reward.select(:brand).order(:brand).distinct

		brands = ds.collect do |reward|
			{
				name: reward.brand
			}
		end

		brands
	end

	def upload_gallery_images params
		raise "Zip file is required" if !params[:zipfile]

		zipfile = params[:zipfile][:tempfile]

		Zip.on_exists_proc = true


		Zip::File.open(zipfile) do |zip_file|
			zip_file.each do |entry|
				next if entry.name.downcase.include? '__macosx'
				if entry.file?
					filename = entry.name.split('/').pop

					code = filename.split('-')[0].upcase
					reward = Reward.where(code: code).first

					if reward
						reward.update(
							image: "#{filename}"

						)
						entry.extract "#{ENV['UPLOADS_DIR']}/gallery/products/pics/#{filename}"
						entry.extract "#{ENV['IMAGES_DIR']}/rewards/products/pics/#{filename}"

					# entry.extract "#{ENV['UPLOADS_DIR']}/gallery/products/pics/#{filename}"
					end
				end
			end
		end
	end

	def get_gallery_images
		dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/uploads/gallery/products/pics'))

		entries = Dir.entries dir

		ret = []

		entries.each_with_index do |file, index|
			next if File.directory? file
			ret.push({
				name: file,
				image_url: "#{ENV['IMAGE_BASE_URL']}/uploads/gallery/products/pics/#{file}?#{Time.now.to_i}"
			})
		end

		ret
	end

	def upload_gallery_thumbnails params
		raise "Zip file is required" if !params[:zipfile]

		zipfile = params[:zipfile][:tempfile]

		Zip.on_exists_proc = true

		Zip::File.open(zipfile) do |zip_file|

			zip_file.each do |entry|
				next if entry.name.downcase.include? '__macosx'
				if entry.file?
					filename = entry.name.split('/').pop
					code = filename.split('-')[0].upcase

					reward = Reward.where(code: code).first

					if reward
						reward.update(
							thumbnail: "#{filename}"

						)

						entry.extract "#{ENV['UPLOADS_DIR']}/gallery/products/thumbs/#{filename}"
						entry.extract "#{ENV['IMAGES_DIR']}/rewards/products/thumbs/#{filename}"

					end
					# entry.extract "#{ENV['UPLOADS_DIR']}/gallery/products/thumbs/#{filename}"
				end
			end
		end
	end

	def get_gallery_thumbnails
		dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/uploads/gallery/products/thumbs'))

		entries = Dir.entries dir

		ret = []

		entries.each do |file|
			next if File.directory? file
			ret.push({
				name: file,
				image_url: "#{ENV['IMAGE_BASE_URL']}/uploads/gallery/products/thumbs/#{file}?#{Time.now.to_i}"
			})
		end

		ret
	end

	def order_update_details params,
		file = params[:file][:tempfile]

		ret = nil

		workbook = Roo::Spreadsheet.open file

		firstsheet = workbook.sheet(0)

		order_update_counter = 0
		order_exists_counter = 0
		order_skipped = 0
		order_rejected = 0

		records_skipped = []
		records_rejected = []
		orderItems = []

		DB.transaction do

			firstsheet.each_with_index(
				suborder_number: 'Sub Order ID',
				dispatch_date: 'Dispatch Date',
				dispatch_awb_no: 'Dispatch AWB No',
				dispatch_courier: 'Dispatch Courier',
				delivery_date: 'Delivery Date',
				status: 'Status',
				remarks: 'Remarks'
			)do |row, ind|
			next if ind < 1

				suborder_number = row[:suborder_number].to_s
				status = row[:status].to_s

				dispatch_awb_no = row[:dispatch_awb_no]
				dispatch_courier = row[:dispatch_courier]
				remarks = row[:remarks]
				dispatch_date = row[:dispatch_date]
				delivery_date = row[:delivery_date]

				record = {
					suborder_number: suborder_number,
					dispatch_date: dispatch_date,
					dispatch_awb_no: dispatch_awb_no,
					dispatch_courier: dispatch_courier,
					delivery_date: delivery_date,
					status: status,
					remarks:remarks
				}

				if suborder_number.empty?
					order_rejected += 1
					records_skipped.push suborder_number
					record['msg'] = 'Sub_order Number is required';
					records_rejected.push record
					next
				end

				sub_order_exists  = OrderItem.where(suborder_number: suborder_number).first

				if !sub_order_exists
					order_rejected += 1
					records_skipped.push suborder_number
					record['msg'] = 'Invalid Sub_order number'
					records_rejected.push record
					next
				end

				begin
					dispatch_date = Date.parse(row[:dispatch_date].to_s) if !row[:dispatch_date].nil?
					delivery_date = Date.parse(row[:delivery_date].to_s) if !row[:delivery_date].nil?

				rescue ArgumentError
					order_rejected += 1
					record['msg'] =  "Invalid date"
					records_rejected.push record
					next
				end

				status = status.downcase

				if status.empty?
					order_rejected += 1
					record['msg'] =  "Status is required"
					records_rejected.push record
					next
				end

				if status == "dispatched"

					a = []
					if dispatch_awb_no.to_s.empty?
						a.push ' AWB NO, '
					end

					if dispatch_courier.to_s.empty?
						a.push ' Dispatch courier, '
					end

					if dispatch_date.to_s.empty?
						a.push ' Dispatch Date, '
					end

					if dispatch_awb_no.to_s.empty? || dispatch_courier.to_s.empty? || dispatch_date.to_s.empty?
						order_rejected += 1
						records_skipped.push suborder_number
						a.push ' - is required'
						record['msg'] =  a.join
						records_rejected.push record
						next
					end
				end

				if status == "delivered" and delivery_date.to_s.empty?
					order_rejected += 1
					records_skipped.push suborder_number
					record['msg'] = 'Delivery date is required'
					records_rejected.push record
					next
				end

				if status == "canceled" and remarks.to_s.empty?
					order_rejected += 1
					records_skipped.push suborder_number
					record['msg'] = 'Remarks is required'
					records_rejected.push record
					next
				end

				orderdetail = OrderItem.where(suborder_number: suborder_number).first

				if orderdetail
					order = Order.where(id: orderdetail.order_id).first
					user = DB[:users].where(id: order.user_id).first

					if orderdetail.status == "redeemed" and status == "delivered" and (dispatch_awb_no.to_s.empty? || dispatch_courier.to_s.empty? || dispatch_date.nil?)
						order_rejected += 1
						records_skipped.push suborder_number
						record['msg'] = 'Dispatched details required'
						records_rejected.push record
						next
					end

					if orderdetail.status == "dispatched" and (status == "redeemed" || status == "dispatched")
						order_rejected += 1
						records_skipped.push suborder_number
						record['msg'] = 'The order is already dispatched'
						records_rejected.push record
						next
					end

					if orderdetail.status == "delivered" and (status == "redeemed" || status == "dispatched")
						order_rejected += 1
						records_skipped.push suborder_number
						record['msg'] = 'The order is already delivered'
						records_rejected.push record
						next
					end

					if orderdetail.status == "canceled"  and (status == "redeemed" || status == "dispatched" || status == "delivered" || status == "canceled")
						order_rejected += 1
						records_skipped.push suborder_number
						record['msg'] = 'The order is canceled'
						records_rejected.push record
						next
					end

					if status == "delivered"
						if dispatch_date.nil?
							if orderdetail.dispatch_date > delivery_date
								order_rejected += 1
								record['msg'] =  "Delivery date should be greater than dispatched date"
								records_rejected.push record
								next
							end
						else
							if dispatch_date > delivery_date
								order_rejected += 1
								record['msg'] =  "Delivery date should be greater than dispatched date"
								records_rejected.push record
								next
							end
						end
					end

					order_update_counter += 1
					point = Point.where(user_id: orderdetail[:user_id]).first
					if status == 'canceled'
						point.update(
							redeemed: point.redeemed - orderdetail.points*orderdetail.quantity
						)
					end

					balance_points =  point.earned - point.redeemed

					orderdetail.update(
						suborder_number: suborder_number,
						dispatch_date: dispatch_date,
						dispatch_awb_num: dispatch_awb_no,
						dispatch_courier: dispatch_courier,
						delivery_date: delivery_date,
						status: status,
						remarks: remarks
					)

					if user[:mobile]
						if orderdetail[:status] == 'dispatched'
							send_sms_helpdesk_status_dispatched user,orderdetail
						elsif orderdetail[:status] == 'delivered'
							send_sms_helpdesk_status_delivered user,orderdetail
						# elsif orderdetail[:status] == 'canceled'
						# 	send_sms_helpdesk_status_canceled user,orderdetail
						end
					end

				else
					order_rejected += 1
					records_skipped.push suborder_number
					next
				end
			end

			# puts '---------------------------------------------'
			# puts "#{order_update_counter} requests were updated"
			# puts "#{order_rejected} requests were rejected"
			# puts "#{records_skipped} requests were rejected"
			# puts '---------------------------------------------'

			if !records_rejected.empty?
				str = ''
				recs = records_rejected.each do |rec|
					str +=	[
						rec[:suborder_number],
						rec[:status],
						rec['msg']
					].join('  ')
					str += "\n"
				end
			end

			ret = {
				updated: order_update_counter,
				rejected: order_rejected,
				records_skipped: records_skipped,
				records_rejected: str
			}
		end
	end

	def get_loginreport start, page, limit, filters

		d = Device.dataset
		d = d.join(:users , :id => Sequel[:devices][:user_id], Sequel[:users][:deleted_at] => nil, :role => 'p').exclude(token: nil)
		d = d.join(:participant_details, :user_id => Sequel[:users][:id])
		d = d.join(:permissions, :user_id => Sequel[:users][:id])
		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id , :state_id)
		.select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id, :state_id)

		d = d.join(address_ds, :address_user_id => :user_id)
		d = d.join(:cities, :id => :city_id).select_append(Sequel[:cities][:name].as(:address_city))
		d = d.join(:states, :id => :state_id).select_append(Sequel[:states][:name].as(:address_state))
		d = d.select(
			Sequel[:devices][:created_at],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:cities][:name].as(:city_name),
			Sequel[:states][:name].as(:state_name),
			Sequel[:participant_details][:store_name],
			Sequel[:permissions][:role_name],
		)

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				end
			end
		end

		if from_date and to_date
			d = d.where(Sequel[:devices][:created_at] => from_date..to_date)
		end

		rec = d.collect do |device|
				{
					login_date:device[:created_at],
					name: device[:name],
					mobile: device[:mobile],
					email: device[:email],
					city:device[:city_name],
					state:device[:state_name],
					store_name:device[:store_name],
					role: device[:role_name]
				}
			end
		rec

	end

	def loginreport_download  filters


		d = Device.dataset
		d = d.join(:users , :id => Sequel[:devices][:user_id], Sequel[:users][:deleted_at] => nil, :role => 'p').exclude(token: nil)
		d = d.join(:participant_details, :user_id => Sequel[:users][:id])
		d = d.join(:permissions, :user_id => Sequel[:users][:id])

		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id , :state_id)
		.select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id, :state_id)

		d = d.join(address_ds, :address_user_id => :user_id)
		d = d.join(:cities, :id => :city_id).select_append(Sequel[:cities][:name].as(:address_city))
		d = d.join(:states, :id => :state_id).select_append(Sequel[:states][:name].as(:address_state))

		d = d.select(
			Sequel[:devices][:created_at],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:cities][:name].as(:city_name),
			Sequel[:states][:name].as(:state_name),
			Sequel[:participant_details][:store_name],
			Sequel[:permissions][:role_name],
		)

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				end
			end
		end

		if from_date and to_date
			d = d.where(Sequel[:devices][:created_at] => from_date..to_date)
		end

		Thread.new do
			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: d.count,
				type: 'login'
				)

			rec = d.collect do |device|
					[
						device[:created_at],
						device[:name],
						"=\"#{device[:mobile]}\"",
						device[:email],
						device[:store_name],
						device[:role_name],
						device[:city_name],
						device[:state_name]

					]
				end


			file_csv = CSV.generate do |csv|
				csv << ['Login Date','Name', 'Mobile', 'Email' ,'Store Name' ,'Role','City','State']
				rec.each { |row| csv << row }
			end

			filename = 'Login_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end
		end
		true
	end

	def registration_download  filters
		ds = Address.dataset.distinct.select(Sequel[:addresses][:user_id])
		ds = ds.join(:states, :id => :state_id)
		ds = ds.join(:cities, :id => Sequel[:addresses][:city_id])
		ds = ds.join(:users, :id => Sequel[:addresses][:user_id], Sequel[:users][:deleted_at] => nil, :role => 'p')
		ds = ds.select(Sequel[:addresses][:user_id]).distinct
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id], :role_name => ['dl','rsa'])
		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'role'
					ds = ds.where(Sequel[:permissions][:role_name] => filter['value'].downcase)
				elsif filter['property'] == 'state'
					ds = ds.where(Sequel[:addresses][:state_id] => filter['value'])
				elsif filter['property'] == 'city'
					ds = ds.where(Sequel[:addresses][:city_id] => filter['value'])
				elsif filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'active'
					ds = ds.where(Sequel[:users][:active] => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.ilike(Sequel[:users][:name], query_string) }
				end
			end
		end

		if from_date and to_date
			ds = ds.where(Sequel[:users][:created_at] => from_date..to_date)
		end

		total = ds.count
		recs = []
		ds.each_with_index do |rec, ind|
			# break if ind > limit
			recs.push self.get_participant_detail rec.participant
		end

		Thread.new do
			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: ds.count,
				type: 'registrations'
				)

			report =recs.collect do |rec|
				[
					rec[:created_at],
					rec[:name],
					"=\"#{rec[:mobile]}\"",
					rec[:referred_by],
					rec[:email],
					rec[:city_name],
					rec[:state_name],
					rec[:store_name],
					rec[:mapped_dealer_name],
					"=\"#{rec[:mapped_dealer_mobile]}\"",
					rec[:mapped_cso_name],
					"=\"#{rec[:mapped_cso_mobile]}\"",
					"=\"#{rec[:dob]}\"",
					"=\"#{rec[:doa]}\"",
					"=\"#{rec[:doj]}\"",
					rec[:experience],
					rec[:mother_tongue],
					rec[:qualification],
					rec[:participant_type],


				]
			end

			file_csv = CSV.generate do |csv|
				csv << ['Enrolment date','Participant Name','Participant Number','Referred By','Email ID','City','State','Store Name','Mapped Dealer Name','Mapped Dealer number',	'Mapped SO Name',	'Mapped SO number',	'DOB',	'DOA',	'DOJ',	'Total Experience',	'Mother tongue',	'Education',	'Participant role'
				]
				report.each { |row| csv << row }
			end

			filename = 'Registration_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end
		end
	end

	def get_quiz_report start, page, limit, filters

		ds = Participant.dataset
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id],:role_name=> ['rsa'])
		ds = ds.join(:participant_details,:user_id => Sequel[:users][:id])

		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id , :state_id)
		.select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id, :state_id)

		ds = ds.join(address_ds, :address_user_id => Sequel[:users][:id])
		ds = ds.join(:cities, :id => :city_id)
		ds = ds.join(:states, :id => :state_id)



		ds = ds.cross_join(:topics)
		ds = ds.select(
			Sequel[:users][:id],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:cities][:name].as(:address_city),
			Sequel[:states][:name].as(:address_state),
			Sequel[:participant_details][:store_name],
			Sequel[:permissions][:role_name],
			Sequel[:topics][:topic],
			Sequel[:topics][:id].as(:topic_id),
			Sequel[:topics][:month],

		)

		from_date = nil
		to_date = nil
		if filters
			filters.each do |filter|
				if filter['property'] == 'month'

					ds = ds.where(Sequel[:topics][:month] => filter['value'])
				elsif filter['property'] == 'year'
					ds = ds.where(Sequel[:topics][:year] => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.ilike(Sequel[:users][:name], query_string) }
				end
			end
		end
		if from_date and to_date
			ds = ds.where(Sequel[:claims][:created_at] => from_date..to_date)
		end

		total = ds.count
		points = nil
		attempted = nil
		user = ds.paginate(page, limit).collect do |user|


			attempted_ds = Quizresponse.dataset.where(:user_id => user[:id],:topic_id => user[:topic_id])
			claim = Claim.dataset.where(:user_id => user[:id],:topic_id => user[:topic_id]).first
			if claim
				# if claim.topic_id
					points = claim[:total_points]
					status = 'Completed'
				# else
				# 	points = 0
				# 	status = 'Pending'
				# end
			else
				points = 0
				status = 'Pending'
			end

			{
				# created_at: claim[:created_at],
				mobile: user[:mobile],
				name: user[:name],
				email: user[:email],
				points_earned: points,
				status: status,
				store_name: user[:store_name],
				city: user[:address_city],
				state: user[:address_state],
				role: user[:role_name],
				topic: user[:topic],
				attempted: attempted_ds.count
			}
		end

		return user,total

	end

	def quizreport_download filters

		ds = Participant.dataset
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id],:role_name=> ['rsa'])
		ds = ds.join(:participant_details,:user_id => Sequel[:users][:id])

		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id , :state_id)
		.select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id, :state_id)

		ds = ds.join(address_ds, :address_user_id => Sequel[:users][:id])
		ds = ds.join(:cities, :id => :city_id)
		ds = ds.join(:states, :id => :state_id)

		ds = ds.cross_join(:topics)
		ds = ds.select(
			Sequel[:users][:id],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:cities][:name].as(:address_city),
			Sequel[:states][:name].as(:address_state),
			Sequel[:participant_details][:store_name],
			Sequel[:permissions][:role_name],
			Sequel[:topics][:topic],
			Sequel[:topics][:id].as(:topic_id)
		)

		from_date = nil
		to_date = nil
		if filters
			filters.each do |filter|
				if filter['property'] == 'month'
					ds = ds.where(Sequel[:topics][:month] => filter['value'])
				elsif filter['property'] == 'year'
					ds = ds.where(Sequel[:topics][:year] => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.ilike(Sequel[:users][:name], query_string) }
				end
			end
		end
		if from_date and to_date
			ds = ds.where(Sequel[:claims][:created_at] => from_date..to_date)
		end

		total = ds.count
		points = nil
		attempted = nil

		Thread.new do

			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: ds.count,
				type: 'quiz'
				)
			user = ds.collect do |user|
				attempted_ds = Quizresponse.dataset.where(:user_id => user[:id],:topic_id => user[:topic_id])
				claim = Claim.dataset.where(:user_id => user[:id],:topic_id => user[:topic_id]).first

				# claim = Claim.dataset.where(:user_id => user[:id]).first

				if claim
					points = claim[:total_points]
					status = 'Completed'
				else
					points = 0
					status = 'Pending'
				end

				[
					# created_at: claim[:created_at],
					user[:name],
					"=\"#{user[:mobile]}\"",
					user[:email],
					user[:topic],
					points,
					attempted_ds.count,
					status,
					user[:store_name],
					user[:address_city],
					user[:address_state],
					user[:role_name],
				]
			end
			file_csv = CSV.generate do |csv|

				csv << ['Participant Name','Participant Number','Email ID','Topic','Points earned','Attempted','Status','Store Name','City','State','Participant role'
				]
				user.each { |row| csv << row }
			end

			filename = 'Quiz_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end

		end
		true


	end

	def get_claims start, page, limit, filters

		d = Claim.dataset.exclude(:type => 'upload points')
		d = d.join(:users,:id => :user_id, :role => 'p')
		d = d.join(:participant_details,:user_id => Sequel[:claims][:user_id])
		d = d.join(:permissions,:user_id => Sequel[:users][:id])

		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id , :state_id)
		.select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id, :state_id)

		d = d.join(address_ds, :address_user_id => Sequel[:users][:id])
		d = d.join(:cities, :id => :city_id)
		d = d.join(:states, :id => :state_id)
		# d = d.left_join(:coupons).where(Sequel[:coupons][:id] => Sequel[:claims][:coupon_id])
		d = d.select(
			Sequel[:claims][:created_at],
			Sequel[:claims][:type],
			Sequel[:claims][:coupon_id],
			Sequel[:claims][:total_points],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:cities][:name].as(:city_name),
			Sequel[:states][:name].as(:state_name),
			Sequel[:participant_details][:store_name],
			Sequel[:permissions][:role_name]

		)

		from_date = nil
		to_date = nil
		if filters
			filters.each do |filter|
				if filter['property'] == 'type'
					d = d.where(Sequel[:claims][:type] => filter['value'].downcase)
				elsif filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				# elsif filter['property'] == 'state'
				# 	ds = ds.where(:address_state_id => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					# ds = ds.where(Sequel.like(Sequel[:users][:mobile], query_string))
					d = d.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.ilike(Sequel[:users][:name], query_string) }
				end
			end
		end
		if from_date and to_date
			d = d.where(Sequel[:claims][:created_at] => from_date..to_date)
		end

		total = d.count
		claims = d.paginate(page, limit).collect do |claim|

			if claim[:coupon_id]
				coupon = Coupon.dataset.where(:id => claim[:coupon_id]).first
				if coupon

					serial_no = coupon.serial_no
					material_group = coupon.product.group
				end
			end
			{
				created_at: claim[:created_at],
				mobile: claim[:mobile],
				name: claim[:name],
				email: claim[:email],
				points_earned: claim[:total_points],
				store_name: claim[:store_name],
				city: claim[:city_name],
				state: claim[:state_name],
				type: claim[:type],
				serial_no: serial_no,
				material_grp: material_group,
				role:claim[:role_name]

			}
		end


		return claims, total
	end

	def claimsreport_download filters
		ds = Claim.dataset.exclude(:type => 'upload points')
		ds = ds.join(:users,:id => :user_id, :role => 'p')
		ds = ds.join(:participant_details,:user_id => Sequel[:claims][:user_id])
		ds = ds.join(:permissions,:user_id => Sequel[:users][:id])
		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id , :state_id)
		.select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id, :state_id)

		ds = ds.join(address_ds, :address_user_id => Sequel[:users][:id])
		ds = ds.join(:cities, :id => :city_id).select_append(Sequel[:cities][:name].as(:address_city))
		ds = ds.join(:states, :id => :state_id).select_append(Sequel[:states][:name].as(:address_state))
		# ds = ds.left_join(:coupons).where(Sequel[:coupons][:id] => Sequel[:claims][:coupon_id])
		ds = ds.select(
			Sequel[:claims][:created_at],
			Sequel[:claims][:type],
			Sequel[:claims][:coupon_id],
			Sequel[:claims][:total_points],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:cities][:name].as(:city_name),
			Sequel[:states][:name].as(:state_name),
			Sequel[:participant_details][:store_name],
			Sequel[:permissions][:role_name],
			# Sequel[:coupons][:serial_no],
			# Sequel[:coupons][:material],

		)

		from_date = nil
		to_date = nil
		if filters
			filters.each do |filter|
				if filter['property'] == 'type'
					ds = ds.where(Sequel[:claims][:type] => filter['value'].downcase)
				elsif filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				# elsif filter['property'] == 'state'
				# 	ds = ds.where(:address_state_id => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					# ds = ds.where(Sequel.like(Sequel[:users][:mobile], query_string))
					ds = ds.where{Sequel.like(Sequel[:users][:mobile], query_string) | Sequel.ilike(Sequel[:users][:name], query_string) }
				end
			end
		end
		if from_date and to_date
			ds = ds.where(Sequel[:claims][:created_at] => from_date..to_date)
		end

		total = ds.count

		Thread.new do

			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: ds.count,
				type: 'claims'
				)
			claims = ds.collect do |claim|
				if claim[:coupon_id]
					coupon = Coupon.dataset.where(:id => claim[:coupon_id]).first
					if coupon
						serial_no = coupon.serial_no
						material_grp = coupon.product.group
					end
				end

				[
					claim[:created_at],
					claim[:name],
					"=\"#{claim[:mobile]}\"",
					claim[:email],
					claim[:city_name],
					claim[:state_name],
					claim[:type],
					"=\"#{serial_no}\"",
					material_grp,
					# claim[:material_group],
					claim[:total_points],
					claim[:role_name],
					claim[:store_name]

				]
			end

			file_csv = CSV.generate do |csv|

				csv << ['Claim date','Participant Name','Participant Number','Email ID','City','State','Claim Type','Serial number submitted','Material Group','Points earned','Participant role','Store Name'
				]
				claims.each { |row| csv << row }
			end

			filename = 'Claims_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end
		end
		true

	end

	def get_points page, start, limit, filters

		ds = get_points_query filters

		# if filters
		# 	filters.each do |filter|
		# 		# if filter['property'] == 'fromdate'
		# 		# 	from_date = (Date.parse filter['value']).to_time
		# 		# elsif filter['property'] == 'todate'
		# 		# 	to_date = (Date.parse filter['value']).to_time
		# 			# to_date = to_date + (24  60  60)
		# 		if filter['property'] == 'state'
		# 			ds = ds.where(:state_id => filter['value'])
		# 		elsif filter['property'] == 'city'
		# 			ds = ds.where(:city_id => filter['value'])
		# 		end
		# 	end
		# end
		# y ds.all
		total = ds.count

		recs = []

		# DB.fetch(sql) do |row|
		ds.paginate(page, limit).each do |row|
			earned_points=0
			redeemed_points=0
			if filters.nil?
				earned_points=row[:total_earned_points].to_i
				redeemed_points=row[:total_redeemed_points].to_i
			else
				earned_points=row[:earned_points].to_i
				redeemed_points=row[:redeemed_points].to_i
			end


			recs.push(
				id: row[:id],
				mobile: row[:mobile],
				name: row[:name],
				store_name: row[:store_name],
				role: row[:role_name],
				city_id: row[:city_id],
				state_id: row[:state_id],
				city: row[:city],
				state: row[:state],
				earned_points:earned_points,
				redeemed_points: redeemed_points,
				total_earned_points: row[:total_earned_points].to_i,
				total_redeemed_points: row[:total_redeemed_points].to_i,
				total_balance_points: row[:total_balance_points].to_i,
			)
		end
		return recs, total
	end

	def get_points_query filters
		true_val = DB.database_type.to_s.include?('sqlite') ? 1 : true

		state_id  = nil
		city_id = nil
		mobile = nil
		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'state'
					state_id = filter['value'].to_i
				elsif filter['property'] == 'city'
					city_id = filter['value'].to_i
				elsif filter['property'] == 'query'
					mobile = filter['value'].to_s
				end
			end
		end

		query_from_date = DateTime.new(2000, 1, 1)
		query_to_date = DateTime.now

		if !from_date.nil? and !to_date.nil?
			# query_from_date = DateTime.new(from_date.year, from_date.month, from_date.day, from_date.hour, from_date.min, from_date.sec)
			# query_to_date = DateTime.new(to_date.year, to_date.month, to_date.day, to_date.hour, to_date.min, to_date.sec)
			query_from_date = DateTime.new(from_date.year, from_date.month, from_date.day, 0, 0, 0)
			query_to_date = DateTime.new(to_date.year, to_date.month, to_date.day, 0, 0, 0)
			query_to_date += 1

		end


		# query_from_date = query_from_date.to_date.iso8601
		# query_to_date = query_to_date.to_date.iso8601

		ds = Participant.dataset.where(:active => true,:role=> 'p')
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id],:role_name => ['rsa'])

		address_ds = Address.dataset.
		select(Sequel.as(:user_id, :address_user_id), :city_id).
		select_append{ min(Sequel[:addresses][:id]).as(:address_id) }.
		group(:address_user_id, :city_id)


		ds = ds.join(address_ds, :address_user_id => Sequel[:users][:id])
		ds = ds.join(:cities, :id => :city_id)
		ds = ds.join(:states, :id => :state_id)

		if state_id
			ds = ds.where(Sequel[:states][:id] => state_id)
		end
		if city_id
			ds = ds.where(Sequel[:cities][:id] => city_id)
		end

		ds = ds.join(:participant_details, :user_id => Sequel[:users][:id])


		claims_ds = Claim.dataset.
		where(Sequel[:claims][:created_at] => from_date..to_date).
		select(Sequel.as(:user_id, :claim_user_id)).
		select_append{ (sum(:total_points) - sum(:points_debited)).as(:earned_points)}.
		group(:claim_user_id)

		# ds = ds.left_join(claims_ds, :claim_user_id => Sequel[:users][:id])
		ds = ds.join(claims_ds, :claim_user_id => Sequel[:users][:id])

		orders_ds = Order.dataset.
		where(Sequel[:orders][:created_at] => from_date..to_date).
		select(Sequel.as(:user_id, :order_user_id)).
		select_append{ sum(:points).as(:redeemed_points)}.
		group(:order_user_id)

		ds = ds.left_join(orders_ds, :order_user_id => Sequel[:users][:id])

		points_ds = Point.dataset.
		select(Sequel.as(:user_id, :pt_user_id)).
		select_append{(sum(:earned).as( :total_earned_points))}.
		select_append{(sum(:redeemed).as( :total_redeemed_points))}.
		select_append {(sum(:earned) - sum(:redeemed)).as(:total_balance_points) }.
		group(:pt_user_id)

		ds = ds.left_join(points_ds, :pt_user_id => Sequel[:users][:id])

		if mobile
			ds = ds.where{Sequel.like(Sequel[:users][:mobile], "%#{mobile}%") | Sequel.ilike(Sequel[:users][:name], "%#{mobile}%") }
		end

		ds = ds.select(
			Sequel[:users][:id],
			Sequel[:users][:name],
			Sequel[:users][:email],
			Sequel[:users][:mobile],
			Sequel[:permissions][:role_name],
			Sequel[:participant_details][:store_name],
			Sequel[:cities][:name].as(:city),
			Sequel[:cities][:id].as(:city_id),
			Sequel[:states][:name].as(:state),
			Sequel[:states][:id].as(:state_id),
			:total_earned_points,
			:total_redeemed_points,
			:earned_points,
			:redeemed_points,
			:total_balance_points
		)

		ds
	end

	def get_points_download filters

		ds = get_points_query filters

		# total = DB.fetch(sql).count

		points = []

		Thread.new do
			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: ds.count,
				type: 'points'
				)
			ds.collect do |row|
				row[:mobile][0..1] = ''

				if row[:redeemed_points].nil?
					row[:redeemed_points] = 0
				end

				points.push(
					[
						"=\"#{ row[:mobile]}\"",
						row[:name],
						row[:email],
						row[:store_name],
						row[:city],
						row[:state],
						row[:total_earned_points],
						row[:earned_points],
						row[:total_redeemed_points],
						row[:redeemed_points],
						row[:total_balance_points],
						row[:role_name],
					]
				)
			end

			file_csv = CSV.generate do |csv|
				csv << ['Mobile', 'Name', 'Email','Store Name','City', 'State', 'Total Earned Points(YTD)','Points Earned(Btw Dates Selected) ', 'Total Redeemed Points(YTD)','Points Redeemed(Btw dates selected)', 'Balances points','Participant Role']
				points.each { |row| csv << row }
			end
			filename = 'Points_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end

		end
		true

	end

	def get_redemption start, page, limit, filters
		ds = Order

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where(Sequel.like(Sequel[:orders][:mobile], query_string))
				end
			end
		end

		if from_date and to_date
			ds = ds.where(Sequel[:orders][:created_at] => from_date..to_date)
		end

		total = ds.count

		recs = []
		ds.drop(start).each_with_index do |order, ind|
			break if ind > limit
			recs.push({
				redemptionid: order.id,
				created_at: order.created_at,
				order_number: order.order_number,
				name: order.name,
				role: order.participant.permission.role_name,
				mobile: order.mobile,
				email: order.participant.email,
				points: order.points,
				address1: order.address1,
				address2: order.address2,
				city: order.city,
				state: order.state,
				pincode: order.pincode
			})
		end
		return recs, total
	end

	def redemption_download filters
		ds = Order.dataset

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'mode'
					ds = ds.where(Sequel[:orders][:via] => filter['value'])
				elsif filter['property'] == 'status'
					ds = ds.where(Sequel[:orders][:status] => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where(Sequel.like(Sequel[:orders][:mobile], query_string))
				end
			end
		end

		if from_date and to_date
			ds = ds.where(Sequel[:orders][:created_at] => from_date..to_date)
		end

		redemptions = []
		Thread.new do
			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: ds.count,
				type: 'redemptions'
				)

			ds.each do |order|
				orderitems = order.items.each do |orderitem|
					redemptions.push([
						order.name,
						"=\"#{order.mobile}\"",
						order.participant.email,
						order.participant.permission.role_name,
						order.order_number,
						orderitem.status,
						order.address1,
						order.address2,
						order.city,
						order.state,
						order.pincode,
						order.created_at.strftime("%Y-%m-%d"),
						orderitem.category_name,
						orderitem.sub_category_name,
						orderitem.quantity,
						orderitem.points,
						orderitem.name,
						orderitem.model_number,
						orderitem.code,
						orderitem.brand,
						orderitem.description.squeeze,
						orderitem.suborder_number,
						# orderitem.status,
						orderitem.dispatch_courier,
						orderitem.dispatch_date,
						orderitem.delivery_date,
						orderitem.dispatch_awb_num,
						orderitem.remarks,
					])
				end
			end

			file_csv = CSV.generate do |csv|
				csv << [ 'Name', 'Mobile', 'Email', 'Role', 'Order ID', 'Status', 'Address1', 'Address2', 'City', 'State', 'Pincode', 'Order Date', 'Category', 'Sub Category', 'Quantity', 'Points', 'Product Name', 'Model Number', 'Product Code', 'Brand', 'Description', 'Sub Order Number', 'Courier Name', 'Dispatch Date', 'Delivery Date', 'AWB No', 'Remarks']
				redemptions.each { |row| csv << row }
			end

			filename = 'Points_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end
		end
		true
	end

	def get_levels_report start, page, limit, filters

		from_date = nil
		to_date = nil

		ds = Participant.dataset.where(:role => 'p')
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id],:role_name=> ['rsa'])
		ds = ds.join(:participant_details,:user_id => Sequel[:users][:id])


		if filters
			filters.each do |filter|
				if filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where(Sequel.like(Sequel[:users][:mobile], query_string))
				end
			end
		end

		level_ds = Levelquizresponse.dataset.where(:completed => true ,:created_at => from_date..to_date).select(
			:user_id,
			:level_title_id,
			Sequel.as(:created_at, :completion_created_at)
		).group(:user_id ,:level_title_id,:created_at)

		ds = ds.join(level_ds, :user_id => Sequel[:users][:id])
		# if from_date and to_date
		# 	ds = ds.where(Sequel[:levels_quizresponse][:completion_created_at]=> from_date..to_date)
		# end


		user_counter = nil
		recs = []
		# * creating recs array to collect all the levels data of particular user from multiple records
		report = []
		# * creating report array to collect all the records from recs array
		total = ds.count

		points = 0
		levels = ds.paginate(page,limit).each_with_index do |user,index|
			if user_counter.nil? or user_counter != user.id
				level = Level.where(:id => user[:level_title_id]).first
				dealer = Participant.where(:id => user[:parent_id]).first
				so = Participant.where(:id => dealer.parent_id).first


				if !user_counter.nil? and user_counter != user.id
					# * if user id is changed then record of recs array is pushed to final report Array
					# * and recs array will get cleared for next user data collection
					# * recs array will be pushed with required keys,values will be updated in further checks below

					report.push recs[0]
					recs.delete_at(0)
					points = 0
					level1 = 'pending'
					level2 = 'pending'
					level3 = 'pending'
					level4 = 'pending'

					recs.push(
						level1: level1,
						level2: level2,
						level3: level3,
						level4: level4,
						points: points,
						user_id: user.id,
						completion_created_at: user[:completion_created_at],
						role_name: user[:role_name],
						mobile: user[:mobile],
						email: user[:email],
						name: user[:name],
						storename: user[:store_name],
						mapped_dealer_name: dealer.name,
						mapped_dealer_mobile: dealer.mobile,
						mapped_so_name: so.name,
						mapped_so_mobile: so.mobile,
					)

					user_counter = user.id

				else
					# * if user_counter is nil(for the first time), it hits this block

					points = 0
					level1 = 'pending'
					level2 = 'pending'
					level3 = 'pending'
					level4 = 'pending'

					recs.push(
						level1: level1,
						level2: level2,
						level3: level3,
						level4: level4,
						points: points,
						user_id: user.id,
						completion_created_at: user[:completion_created_at],
						role_name: user[:role_name],
						mobile: user[:mobile],
						email: user[:email],
						name: user[:name],
						storename: user[:store_name],
						mapped_dealer_name: dealer.name,
						mapped_dealer_mobile: dealer.mobile,
						mapped_so_name: so.name,
						mapped_so_mobile: so.mobile,
					)

					user_counter = user.id

				end

				if level.level == 1
					level1 = 'completed'
					points += 200

					recs[0][:level1] = level1
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]


				elsif level.level == 2
					level2 = 'completed'
					points += 300

					recs[0][:level2] = level2
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]


				elsif level.level == 3
					level3 = 'completed'
					points += 500

					recs[0][:level3] = level3
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]


				elsif level.level == 4
					level4 = 'completed'
					points += 1000

					recs[0][:level4] = level4
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]

				end



			elsif  user_counter == user.id
				level = Level.where(:id => user[:level_title_id]).first

				if level.level == 1
					level1 = 'completed'
					points += 200

					recs[0][:level1] = level1
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]


				elsif level.level == 2

					level2 = 'completed'
					points += 300

					recs[0][:level2] = level2
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]


				elsif level.level == 3
					level3 = 'completed'
					points += 500

					recs[0][:level3] = level3
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]


				elsif level.level == 4
					level4 = 'completed'
					points += 1000

					recs[0][:level4] = level4
					recs[0][:points] = points
					recs[0][:completion_created_at] = user[:completion_created_at]

				end

			end
			# * last record should get push to report array
			if index == total-1
				report.push recs[0]
				recs.delete_at(0)
			end
		end

		return report, report.length

	end

	def levelsreport_download filters
		from_date = nil
		to_date = nil

		ds = Participant.dataset.where( :role => 'p')
		ds = ds.join(:permissions, :user_id => Sequel[:users][:id],:role_name=> ['rsa'])
		ds = ds.join(:participant_details,:user_id => Sequel[:users][:id])


		if filters
			filters.each do |filter|
				if filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where(Sequel.like(Sequel[:users][:mobile], query_string))
				end
			end
		end

		level_ds = Levelquizresponse.dataset.where(:completed => true,:created_at => from_date..to_date).select(
			:user_id,
			:level_title_id,
			Sequel.as(:created_at, :completion_created_at)
		).group(:user_id ,:level_title_id,:created_at)

		ds = ds.join(level_ds, :user_id => Sequel[:users][:id])

		# if from_date and to_date
		# 	ds = ds.where(Sequel[:levels_quizresponse][:completion_created_at]=> from_date..to_date)
		# end

		user_counter = nil

		points = 0
		recs = []
		report = []
		total = ds.count

		Thread.new do
			reportrequest = ReportDownloadRequest.create(
				user_id: self.id,
				requested_time: DateTime.now,
				responded_time: nil,
				status: 'pending',
				total_records: ds.count,
				type: 'levels'
				)

			levels = ds.each_with_index do |user,index|
				if user_counter.nil? or user_counter != user.id
					level = Level.where(:id => user[:level_title_id]).first
					dealer = Participant.where(:id => user[:parent_id]).first
					so = Participant.where(:id => dealer.parent_id).first


					if !user_counter.nil? and user_counter != user.id
						# * if user id is changed then record of recs array is pushed to final report Array
						# * and recs array will get cleared for next user data collection
						# * recs array will be pushed with required keys,values will be updated in further checks below

						report.push recs[0]
						recs.delete_at(0)
						points = 0
						level1 = 'pending'
						level2 = 'pending'
						level3 = 'pending'
						level4 = 'pending'

						recs.push(
							level1: level1,
							level2: level2,
							level3: level3,
							level4: level4,
							points: points,
							user_id: user.id,
							completion_created_at: user[:completion_created_at],
							role_name: user[:role_name],
							mobile: user[:mobile],
							email: user[:email],
							name: user[:name],
							storename: user[:store_name],
							mapped_dealer_name: dealer.name,
							mapped_dealer_mobile: dealer.mobile,
							mapped_so_name: so.name,
							mapped_so_mobile: so.mobile,
						)


						user_counter = user.id

					else
						# * if user_counter is nil(for the first time), it hits this block

						points = 0
						level1 = 'pending'
						level2 = 'pending'
						level3 = 'pending'
						level4 = 'pending'

						recs.push(
							level1: level1,
							level2: level2,
							level3: level3,
							level4: level4,
							points: points,
							user_id: user.id,
							completion_created_at: user[:completion_created_at],
							role_name: user[:role_name],
							mobile: user[:mobile],
							email: user[:email],
							name: user[:name],
							storename: user[:store_name],
							mapped_dealer_name: dealer.name,
							mapped_dealer_mobile: dealer.mobile,
							mapped_so_name: so.name,
							mapped_so_mobile: so.mobile,
						)

						user_counter = user.id

					end

					if level.level == 1
						level1 = 'completed'
						points += 200

						recs[0][:level1] = level1
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]



					elsif level.level == 2
						level2 = 'completed'
						points += 300

						recs[0][:level2] = level2
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]


					elsif level.level == 3
						level3 = 'completed'
						points += 500

						recs[0][:level3] = level3
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]


					elsif level.level == 4
						level4 = 'completed'
						points += 1000

						recs[0][:level4] = level4
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]

					end



				elsif  user_counter == user.id
					level = Level.where(:id => user[:level_title_id]).first


					if level.level == 1
						level1 = 'completed'
						points += 200

						recs[0][:level1] = level1
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]


					elsif level.level == 2

						level2 = 'completed'
						points += 300

						recs[0][:level2] = level2
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]


					elsif level.level == 3
						level3 = 'completed'
						points += 500

						recs[0][:level3] = level3
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]


					elsif level.level == 4
						level4 = 'completed'
						points += 1000

						recs[0][:level4] = level4
						recs[0][:points] = points
						recs[0][:completion_created_at] = user[:completion_created_at]

					end

				end

				# * last record should get push to report array
				if index == total-1
					report.push recs[0]
					recs.delete_at(0)
				end
			end

			csvdownload = []
			report.each do |rec|

				csvdownload.push([
					rec[:completion_created_at].strftime("%Y-%m-%d"),
					rec[:name],
					"=\"#{rec[:mobile]}\"",
					rec[:email],
					rec[:role_name],
					rec[:storename],
					rec[:mapped_dealer_name],
					"=\"#{rec[:mapped_dealer_mobile]}\"",
					rec[:mapped_so_name],
					"=\"#{rec[:mapped_so_mobile]}\"",
					rec[:level1],
					rec[:level2],
					rec[:level3],
					rec[:level4],
					rec[:points]

				])
			end

			file_csv = CSV.generate do |csv|
				csv << [ 'Completion Date','Name', 'Mobile', 'Email', 'Role', 'Store Name', 'Mapped Dealer Mobile', 'Mapped Dealer Name', 'Mapped SO Name', 'Mapped SO Mobile', 'Level1', 'Level2', 'Level3', 'Level4', 'Points']
				csvdownload.each { |row| csv << row }
			end

			filename = 'Levels_report_' + SecureRandom.hex(4).upcase+ '.csv'
			dir = "#{ENV['UPLOADS_DIR']}/reports/#{filename}"

			file_save_as = "#{dir}"
			File.open(file_save_as, "wb") do |save_file|
				save_file.write(file_csv)
			end

			reportrequest.update(
				status: 'Completed',
				download_url: dir,
				filename: filename,
				responded_time: DateTime.now
			)

			if reportrequest[:status] == 'Completed'
				send_email_request_download_success self, reportrequest
			else
				send_email_request_download_failure self, reportrequest

			end
		end
		true

	end

	def get_request_report page, start, limit, filters

		ds = ReportDownloadRequest.dataset

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'type'
					ds = ds.where(:type => filter['value'].downcase)
				elsif filter['property'] == 'fromdate'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'todate'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				end
			end
		end

		if from_date and to_date
			ds = ds.where(:created_at => from_date..to_date)
		end

		total = ds.count

		rec = ds.collect do |request|

			download_url = "#{ENV['IMAGE_BASE_URL']}/uploads/reports/#{request.filename}"

			{
				id:request[:id],
				name: request.helpdeskuser.name,
				email: request.helpdeskuser.email,
				type: request[:type],
				status: request[:status],
				download_url: download_url,
				total_records: request[:total_records],
				requested_time: request[:requested_time],
				responded_time: request[:responded_time]

			}
		end
		return rec,total

	end


end #HelpDeskUser

class Version < Sequel::Model(DB[:versions])
	plugin :paranoid
end

class Device < Sequel::Model(DB[:devices])
	plugin :paranoid
	plugin :secure_password

	many_to_one		:helpdeskuser,
					:key	=> :user_id,
					:class	=> :HelpDeskUser

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

end #Device

class Participant < Sequel::Model(DB[:users].filter(role: 'p').extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid
	plugin :nested_attributes

	one_to_one      :detail,
					:key    =>  :user_id,
					:class  =>  :ParticipantDetail

	one_to_many		:devices,
					:key    =>  :user_id,
					:class	=> :Device

	many_to_one		:parent,
					:key	=> :parent_id,
					:class	=> self

	one_to_one      :permission,
					:key    =>  :user_id,
					:class  =>  :Permission

	nested_attributes :permission

	one_to_many     :addresses,
					:key    =>  :user_id,
					:class  =>  :Address

	one_to_many		:subordinates,
					:key	=> :parent_id,
					:class	=> self

	one_to_many     :claims,
					:key    =>  :user_id,
					:class  =>  :Claim

	one_to_one		:point,
					:key    =>  :user_id,
					:class  =>  :Point

	one_to_many     :cartitems,
					:key    =>  :user_id,
					:class  =>  :CartItem

	one_to_many     :orders,
					:key    =>  :user_id,
					:class  =>  :Order

	many_to_many	:referrals,
					:left_key	=> :referred_by_id,
					:right_key	=> :referred_to_id,
					:join_table	=> :referrals,
					:class		=> :Participant

	one_to_many		:quiz_response,
					:key    =>	 :user_id,
					:class	=>	 :Quizresponse
	# many_to_many	:certificates,
	# 				:left_key	=> :user_id,
	# 				:right_key	=> :level_title_id,
	# 				:join_table	=> :certificates,
	# 				:class	=> :Participant

	one_to_many     :certificates,
					:key    =>  :user_id,
					:class  =>  :Certificate


	one_to_many		:leveluserresponses,
					:key    =>	 :user_id,
					:class	=>	 :Levelquizresponse

	one_to_many		:feedbacks,
					:key    =>	 :user_id,
					:class	=>	 :Feedback


	def role_name; permission.role_name; end
	# def role_name=(v); permission.role_name = v; end

	def pointsearn; permission.pointsearn; end
	# def pointsearn=(v); permission.pointsearn = v; end

	def claim; permission.claim; end
	# def claim=(v); permission.claim = v; end

	def cart; permission.cart; end
	# def redeem=(v); permission.redeem = v; end

	def redemption; permission.redemption; end
	# def redemption=(v); permission.redemption = v; end

	def refer; permission.refer; end
	# def refer=(v); permission.refer = v; end

	def permission
		if s = super
			s
		else
			self.permission_attributes = {}
			super
		end
	end


	def before_destroy
		permission.destroy
		super
	end

	def before_create
		permission
		super
	end

	def after_update
		super
		permission.save
	end

	def validate
		super
		validates_presence [:name]
		validates_unique :mobile, message: 'already exists'

	end

	#*----------------------------------------------------------------------
	#* feedback incoming sms from customer
	#*----------------------------------------------------------------------

	def self.feedback_via_sms params
		customer_mobile, error, ret = nil, nil, nil, nil, 'failure'
		error = 'invalid secret' if params[:secret] != SECRET

		customer_mobile = params[:sender].to_i
		error = 'invalid mobile' if customer_mobile.zero? or params[:sender].length != 12

		keyword = params[:keyword].to_s.downcase
		if keyword[0] == 't'
			keyword[0] = ''
		end

		received_before_6days = params[:received_on].to_time - 6.days


		# fb_requests = Feedback.dataset.where(:customer_mobile => customer_mobile.to_s, :received_on => nil).where[{'created_at < ?', received_before_6days}]
		# fb_requests_ds = Feedback.dataset.where(:customer_mobile => customer_mobile.to_s, :received_on => nil).where{created_at > received_before_6days}
		# fb_requests_ds = Feedback.dataset.where(:customer_mobile => customer_mobile.to_s, :received_on => nil).where(:created_at => received_before_6days..Time.now)
		fb_requests_ds = Feedback.dataset.where(:customer_mobile => customer_mobile.to_s, :received_on => nil).where(:created_at => '2020-05-08 14:40:05'..'2020-05-14 16:31:45')
		fb_requests = fb_requests_ds.first


		cust_mobile_check = Feedback.where(customer_mobile: customer_mobile.to_s).first

		if !cust_mobile_check
			error = 'invalid customer'
			ret = 'failure'
			send_sms_for_unknown_number customer_mobile
			# * sending sms to unknown number
		end

		if !error
			if keyword == 'YES' or keyword == 'Y' or keyword == 'y' or keyword == 'yes'

				if !fb_requests
					error = 'No Feedback requests found'
					ret = 'failure'
				end

				prev_rec_storename = nil
				fb_requests_ds.each do |feed|
					if prev_rec_storename == feed.participant.detail.store_name

					else
						claim_code = SecureRandom.hex(4).upcase
						type = "feedback"
						points = 5

						fb_requests.participant.add_claim(
							code: claim_code,
							total_points: points,
							description: nil,
							category: nil,
							type: type
						)

						part_point = fb_requests.participant.point

						if part_point.nil?

							point_new = Point.new(
								user_id: fb_requests.participant.id,
								earned: points
							)
							point_new.save
						else
							total_points = (part_point.earned) + (points)
							part_point.update(earned: total_points)
						end

						fb_requests.update(
							received_on: params[:received_on]
						)
						balance = fb_requests.participant.get_balance_points

						if fb_requests.participant.mobile
							send_sms_reply_for_yes fb_requests.participant, balance
							# * sending sms to reply for yes -once rsa gets points
						end
						ret = 'success'

					end

					prev_rec_storename = feed.participant.detail.store_name

				end



			elsif keyword == 'NO' or keyword == 'no' or keyword == 'n' or keyword == 'N'
				if fb_requests
					send_sms_reply_for_no fb_requests.participant
					ret = 'failure'
					# * sending sms to rsa for sms reply for no
				end
			else
				send_sms_reply_for_invalid_format customer_mobile
				ret = 'failure'
				#* sending sms to customer for invalid format sms content
			end
		else
			p error
		end
		ret

	end

	def self.verify data
		player_id = data[:player_id]

		mobile = data[:mobile].to_s
		if mobile.length == 10
			mobile = "91#{mobile}"
		end

		part = self.where(mobile: mobile).first

		raise "Your attempt to login was unsuccessful. Please contact 18005729496 for any queries" if !part
		raise "Your account has been deactivated, please contact 18005729496 for more details" if !part.active

		if ENV['RACK_ENV'] == 'production'
			if mobile == '919191919191' # for dummy ios user
				otp = '111111'
			else
				otp = rand(111111..999999)
				send_sms_participant_login_otp part.mobile, otp
			end
		elsif ENV['RACK_ENV'] == 'staging'
			if mobile == '919191919191' || mobile == '918181818181'
				otp = '111111'
			else
				otp = rand(111111..999999)
				send_sms_participant_login_otp part.mobile, otp
			end
		else
			otp = '111111'
			send_sms_participant_login_otp part.mobile, otp
		end

		if ENV['RACK_ENV'].include? 'test'
			expires = DateTime.now + (1.0/(24*60*60))
		else
			expires = DateTime.now + (3.0/24)
		end

		Device.dataset.where(:user_id => part[:id],:player_id => player_id).delete

		part.add_device(
			player_id: player_id,
			otp: otp,
			otp_expires: expires,
			password: 'password',
			password_confirmation: 'password'
		)

		true
	end

	def self.login data
		player_id = data[:player_id]

		mobile = data[:mobile].to_s
		if mobile.length == 10
			mobile = "91#{mobile}"
		end

		part = self.where(mobile: mobile).first

		raise "Invalid mobile number" if !part
		raise "Your account has been deactivated, please contact 18005729917 for more details" if !part.active

		otp = data[:otp].to_s

		device = nil
		if !player_id.to_s.empty?
			device = part.devices_dataset.where(otp: otp, player_id: player_id).last
		else
			device = part.devices_dataset.where(otp: otp).last
		end

		raise "Invalid otp" if !device or device.otp != otp

		now = DateTime.now
		raise "otp has expired" if now > device.otp_expires.to_datetime

		token = SecureRandom.hex(10)
		device.update(
			token: token,
			otp: nil,
			otp_expires: nil,
			user_agent: data[:user_agent]
		)

		ret = {
			name: part.name,
			token: device.token,
			role: part.permission.role_name
		}

		ret.merge!({
			permission: {
				lne: false,
				levels: false
			}
		})
		ret
	end

	def get_balance_points
		cart_points = self.get_cart_points

		if self.point.nil?
			balance = nil
		else
			balance_points = self.point.earned - (self.point.redeemed + cart_points)
		end

		balance_points
	end

	def get_all_points

		cart_points = 0
		balance = 0
		id = 0
		earned = 0
		redeemed = 0
		associate_count = 0
		quiz = 0


		if !self.point.nil?
			cart_points = self.get_cart_points
			balance = self.point.earned - (self.point.redeemed + cart_points)
			id = self.point.id
			earned = self.point.earned
			redeemed = self.point.redeemed
		end

		if permission.role_name == "dl"
			associate_count = self.subordinates.count
			total_pool_points = self.get_pool_points
			quiz = Topic.dataset.count
		elsif permission.role_name == "rsa"
			total_pool_points = self.get_rsa_pool_points
			quiz_status = self.get_quiz_status
		end

		today = Date.today
		month = today.month

		if today.month > 3
			year_start = Date.new(today.year,4).year
			year_end = Date.new(today.year,3,31).next_year().year

		else
			year_start = Date.new(today.year,4).prev_year().year
			year_end = Date.new(today.year,3,31).year
		end


		{
			id: id,
			earned: earned,
			redeemed: redeemed,
			month: month,
			fromyear: year_start,
			toyear: year_end,
			cart: cart_points,
			balance: balance,
			quiz: quiz.nil? ? nil : quiz,
			rsa_count: associate_count.nil? ? nil : associate_count,
			total_dealer_pool_points: total_pool_points.nil? ? nil : total_pool_points[:dealer_earned],
			total_pool_points: total_pool_points.nil? ? nil : total_pool_points[:amount],
			total_upload_points: total_pool_points.nil? ? nil : total_pool_points[:total_upload_points],
			# total_lne_points: total_pool_points.nil? ? nil : total_pool_points[:total_lne_points],
			# total_level_points: total_pool_points.nil? ? nil : total_pool_points[:total_level_points],
			total_coupon_points: total_pool_points.nil? ? nil : total_pool_points[:total_coupon_points],
			num_cartitems: self.cartitems_dataset.not_deleted.count,
			pending_count:quiz_status.nil? ? nil : quiz_status[:pending_count],
			completed_count:quiz_status.nil? ? nil : quiz_status[:completed_count],
			total_upload_deducted_points:total_pool_points.nil? ? nil : total_pool_points[:total_upload_deducted_points]

		}
	end

	def get_pool_points
		dealer_earned = 0
		amount = 0
		total_level_points = 0
		total_lne_points = 0
		total_coupon_points = 0
		total_upload_points = 0
		total_upload_deducted_points = 0

		ret = []

		self.subordinates.each do |rsa|
			if rsa.point
				dealer_earned +=  rsa.point.earned
			end
			rsa.claims.each do |row|
				amount += row[:total_points].to_i

				if row[:type] == 'learn and earn'
					total_lne_points += row[:total_points]
				elsif row[:type] == 'coupon'
					total_coupon_points += row[:total_points].to_i
				elsif row[:type] == 'levels'
					total_level_points += row[:total_points].to_i
				elsif row[:type] == 'upload points'
					total_upload_points += row[:total_points].to_i
					if row[:points_debited] > 0
						total_upload_deducted_points += row[:points_debited].to_i
					end
				end
			end
		end
		{
			dealer_earned: dealer_earned,
			amount: amount,
			# total_lne_points: total_lne_points,
			total_coupon_points: total_coupon_points,
			total_upload_points: total_upload_points,
			total_upload_deducted_points: total_upload_deducted_points.nil? ? nil : total_upload_deducted_points,
			# total_level_points: total_level_points

		}
	end

	def get_rsa_pool_points
		total_lne_points = 0
		total_coupon_points = 0
		total_upload_points = 0
		total_upload_deducted_points = 0
		total_level_points = 0
		self.claims.each do |row|
			if row[:type] == 'learn and earn'
				total_lne_points += row[:total_points].to_i
			elsif row[:type] == 'coupon'
				total_coupon_points += row[:total_points].to_i
			elsif row[:type] == 'upload points'
				total_upload_points += row[:total_points].to_i
				if row[:points_debited] > 0
					total_upload_deducted_points += row[:points_debited].to_i
				end
			elsif row[:type] == 'levels'
				total_level_points += row[:total_points].to_i
			end
		end

		{
			# total_level_points: total_level_points,
			# total_lne_points: total_lne_points,
			total_coupon_points: total_coupon_points,
			total_upload_points: total_upload_points,
			total_upload_deducted_points: total_upload_deducted_points.nil? ? nil : total_upload_deducted_points
		}
	end

	def get_quiz_status
		today = Date.today

		if today.month <= 3
			ds = Topic.dataset.not_deleted.where(published: true, year: today.year-1..today.year)
		else
			ds = Topic.dataset.not_deleted.where(published: true, year: today.year)
		end

		completed_count = 0
		pending_count = 0
		self.claims.each do |row|
			if row[:topic_id]
				completed_count += 1
			end

		end
		pending_count = ds.count - completed_count
		{
			completed_count: completed_count,
			pending_count: pending_count
		}
	end

	def get_cart_points
		self.cartitems_dataset.not_deleted.collect do |item|
			item.quantity * item.reward.points
		end.compact.sum
	end

	def add_to_cart data
		reward = Reward[data[:reward_id].to_i]
		raise 'Invalid reward item' if !reward

		cartitem = CartItem.create(
			quantity: data[:quantity].to_i || 1,
			reward_id: reward.id,
			user_id: self.id
		)

		{
			id: cartitem.id,
			quantity: cartitem.quantity,
			reward_id: cartitem.reward.id,
			reward_name: cartitem.reward.name,
			reward_code: cartitem.reward.code,
			reward_points: cartitem.reward.points,
			reward_image: cartitem.reward.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{cartitem.reward.image}",
			reward_thumbnail:cartitem.reward.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{cartitem.reward.thumbnail}",
		}
	end

	def remove_from_cart cartitem_id
		cartitem = self.cartitems_dataset.not_deleted.where(id: cartitem_id.to_i).first
		raise 'Invalid cart item' if !cartitem

		# ============================================================================= #
		# We don't need to maintain items which are deleted from the cart by the user.  #
		# The only items which need to be maintained in cart after delete are the       #
		# ones which have been moved to an order.                                       #
		# So, for removing cartitems directly -                                         #
		# 		cartitem.destroy                                                        #
		# For moving cartitem to ordertiem -                                            #
		# 		cartitem.soft_delete                                                    #
		# ============================================================================= #
		# cartitem.soft_delete
		cartitem.destroy

		true
	end

	def update_cartitem_quantity cartitem_id, quantity
		cartitem = self.cartitems_dataset.not_deleted.where(id: cartitem_id.to_i).first
		raise 'Invalid cart item' if !cartitem

		cartitem.update(
			quantity: quantity
		)

		{
			id: cartitem.id,
			quantity: cartitem.quantity,
			reward_id: cartitem.reward.id,
			reward_name: cartitem.reward.name,
			reward_code: cartitem.reward.code,
			reward_points: cartitem.reward.points,
			reward_image: cartitem.reward.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{cartitem.reward.image}",
			reward_thumbnail:cartitem.reward.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{cartitem.reward.thumbnail}",
		}
	end

	def get_cartitems
		self.cartitems_dataset.not_deleted.collect do |cartitem|
			{
				id: cartitem.id,
				quantity: cartitem.quantity,
				reward_id: cartitem.reward.id,
				reward_name: cartitem.reward.name,
				reward_code: cartitem.reward.code,
				reward_points: cartitem.reward.points,
				reward_image: cartitem.reward.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{cartitem.reward.image}",
				reward_thumbnail:cartitem.reward.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{cartitem.reward.thumbnail}",
				reward_description: cartitem.reward.description
			}
		end
	end

	def get_addresses
		self.addresses.collect do |address|
			{
				id: address.id,
				name: address.name,
				mobile: address.mobile,
				address1: address.address1,
				address2: address.address2,
				address3: address.address3,
				district: address.district,
				city_id: address.city.nil? ? nil : address.city.id,
				state_id: address.state.nil? ? nil : address.state.id,
				city_name: address.city.nil? ? nil : address.city.name,
				state_name: address.state.nil? ? nil : address.state.name,
				pincode: address.pincode
			}
		end
	end

	def remove_address id
		raise "Minimum one address is required" if self.addresses.count == 1
		address = self.addresses_dataset.where(id: id).first
		address.delete
	end

	def new_address data
		mobile = data[:mobile].to_s

		if mobile.length < 10 or mobile.length > 12 or mobile.length == 11
			raise "Mobile number should be 10 or 12 digits"
		end

		if mobile.length == 10
			mobile = "91#{mobile}"
		end

		address = self.add_address(
			name: data[:name],
			mobile: mobile,
			address1: data[:address1],
			address2: data[:address2],
			address3: data[:address3],
			district: data[:district],
			city_id: data[:city_id],
			state_id: data[:state_id],
			pincode: data[:pincode]
		)

		{
			id: address.id,
			name: address.name,
			mobile: address.mobile,
			address1: address.address1,
			address2: address.address2,
			address3: address.address3,
			district: address.district,
			city_id: address.city.nil? ? nil : address.city.id,
			state_id: address.state.nil? ? nil : address.state.id,
			city_name: address.city.nil? ? nil : address.city.name,
			state_name: address.state.nil? ? nil : address.state.name,
			pincode: address.pincode
		}
	end

	def checkout data
		address = self.addresses_dataset.where(id: data[:address_id]).first
		raise "Invalid address" if !address


		self.cartitems_dataset.not_deleted.each do |cartitem|
			ds = DB[:rewards].where(id: cartitem.reward_id)
			raise "#{ds.first[:name]} is not available. Please remove Item from Cart to proceed" if !ds.first[:active]
		end

		order_number = nil

		DB.transaction do
			# ====================================================
			#    Order status have be in the following sequence -
			#    redeemed
			#    dispatched
			#    delivered
			# ====================================================
			order = self.add_order(
				name: address.name,
				mobile: address.mobile,
				address1: address.address1,
				address2: address.address2,
				district: address.district,
				pincode: address.pincode,
				city: address.city.name,
				state: address.state.name,
			)

			total_orderitems_points = 0

			num_items = 0
			orderitem = 0

			d = DateTime.now
			order_number = "CLnD#{order.id.to_s.rjust(5, "0")}"
			order_number.upcase!


			self.cartitems_dataset.not_deleted.each do |cartitem|
				total_orderitems_points += (cartitem.quantity * cartitem.reward.points)
				num_items += 1

				suborder_number = "#{order_number + SecureRandom.hex(1)}"
				suborder_number.upcase!

				orderitem = order.add_item(
					user_id: order.user_id,
					status: 'redeemed',
					suborder_number: suborder_number,
					name: cartitem.reward.name,
					quantity: cartitem.quantity,
					model_number: cartitem.reward.model_number,
					code: cartitem.reward.code,
					brand: cartitem.reward.brand,
					description: cartitem.reward.description,
					image: cartitem.reward.image,
					thumbnail: cartitem.reward.thumbnail,
					points: cartitem.reward.points,
					category_name: cartitem.reward.category.name,
					sub_category_name: cartitem.reward.sub_category.name
				)

				cartitem.soft_delete
			end

			order.update(
				order_number: order_number,
				points: total_orderitems_points,
				num_items: num_items
			)

			self.point.update(redeemed: self.point.redeemed + total_orderitems_points)

			send_sms_helpdesk_successful_checkout self, order_number, orderitem
		end

		order_number
	end

	def get_orders page, limit, filters, sorter
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?
		ds = self.orders_dataset.not_deleted

		from_date = nil
		to_date = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'from'
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to'
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				# elsif filter['property'] == 'status'
				# 	query_string = "#{filter['value'].to_s.downcase}%"
				# 	ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
				else
					query_string = "#{filter['value'].to_s.upcase}%"
					ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
				end
			end
		end

		if from_date and to_date
			ds = ds.where(created_at: from_date..to_date)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count

		ds = ds.paginate(page, limit)

		recs = ds.collect do |order|
			{
				id: order.id,
				order_number: order.order_number,
				points: order.points,
				num_items: order.num_items,
				date: order.created_at.iso8601,
				name: order.name,
				mobile: order.mobile,
				address1: order.address1,
				address2: order.address2,
				district: order.district,
				city: order.city,
				state: order.state,
				pincode: order.pincode
			}
		end

		return recs, total
	end

	def get_order_details order_id, filters, sorter
		ds = OrderItem.dataset.where(order_id: order_id)
		# ds = self.orders_dataset.where(id: order_id)
		raise "Invalid order" if !ds

		if filters
			filters.each do |filter|
				query_string = "#{filter['value'].to_s.upcase}%"
				ds = ds.where(Sequel.like(Sequel[:orderitems][:suborder_number], query_string))
			end
		end

		ds.collect do |item|
			{
				id: item.id,
				order_number: item.suborder_number,
				status: item.status,
				quantity: item.quantity,
				name: item.name,
				model_number: item.model_number,
				code: item.code,
				brand: item.brand,
				description: item.description,
				image: item.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{item.image}",
				thumbnail:item.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{item.thumbnail}",
				points: item.points,
				date: item.created_at.iso8601,
			}
		end
	end

	def refer_another data
		mobile = data[:mobile].to_s
		if mobile.length == 10
			mobile = "91#{mobile}"
		end

		raise "Cannot refer this mobile number - please refer a different mobile number" if self.mobile == mobile

		hdrequest_exists = DB[:helpdesk_requests].where(mobile: mobile, deleted_at: nil).first
		raise 'Registration is already in process' if hdrequest_exists

		exists = DB[:users].where(mobile: mobile).first
		raise 'Mobile number already exists' if exists

		exists = self.referrals_dataset.where(mobile: mobile).first
		raise 'Mobile number already exists' if exists

		raise 'Name is required' if !data[:name] or data[:name].empty?

		HelpDeskRequest.create(
			type: 'referral',
			mobile: mobile,
			name: data[:name],
			referred_by: self.mobile,
			message: 'referral ' + mobile,
			participant_type: 'rsa',
			status: 'incomplete'
		)

		true
	end

	def verify_coupon data

		if data[:serial_no].length == 16
			serial_no = "00#{data[:serial_no]}"
		else
			serial_no = data[:serial_no]
		end


		coupon = Coupon.where(serial_no: serial_no).first
		raise 'Invalid coupon code' if !coupon or coupon.redeemed
		product = Product.where(id: coupon.product_id).first

		{
			points: product.points,
			material: product.material,
			description: product.description,
			group: product.group,
			measure: product.measure,
			coupon: serial_no,
		}
	end

	def make_claim data
		coupon_codes = data[:serial_no]
		DB.transaction do

			total_coupon_points = 0
			point = self.point

			coupon_codes.each do |code|
				coupon = Coupon.where(serial_no: code).first
				product = Product.where(id: coupon.product_id).first

				raise 'Invalid coupon code' if !coupon or coupon.redeemed

				self.add_claim(
					coupon_id: coupon.id,
					total_points: product.points,
					type: 'coupon',
					code: code
				)

				coupon.update(redeemed: true)

				if point.nil?

					point = Point.new(
						user_id: self.id,
						earned: product.points
					)
					point.save
				else
					total_points = point.earned + product.points
					point.update(earned: total_points)
				end
				total_coupon_points += product.points

			end
			if self.point.nil?
				balance = total_coupon_points
				send_sms_points_earn self, total_coupon_points, balance
			else
				balance = self.get_balance_points
				send_sms_points_earn self, total_coupon_points, balance
			end
		end
	end

	def get_banners
		dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'public/images/banners'))

		entries = Dir.entries dir

		ret = []

		entries.each do |file|
			next if File.directory? file

			ret.push({
				name: file,
				image_url: "#{ENV['IMAGE_BASE_URL']}/images/banners/#{file}?#{Time.now.to_i}"
			})
		end
		ret
	end

	def self.version_check params
		values = Version.where(platform:  params[:platform].downcase).first
		{
			id: values[:id],
			platform: values[:platform],
			vcode: values[:vcode]
		}
	end

	def get_topics_participant page, limit, filters
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		today = Date.today
		# today = Date.new(today1.year,1,8)

		if today.month <= 3
			ds = Topic.dataset.not_deleted.where(published: true, year: today.year-1..today.year)
		else
			ds = Topic.dataset.not_deleted.where(published: true, year: today.year)
		end

		if filters
			filters.each do |filter|
				if filter['property'].downcase == "month"
					ds = ds.where(month: filter['value'].to_i)
				elsif filter['property'].downcase == 'year'
					ds = ds.where(year: filter['value'].to_i)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.ilike(Sequel[:topics][:topic], query_string)}
				end
			end
		end

		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rec|
			attempted = self.claims_dataset.where(topic_id: rec[:id]).first
			attachments = self.get_all_attachments_participant(rec)

			if attempted.nil?
				status = 'Incomplete'
			else
				status = "Complete"
			end

			{
				id: rec.id,
				month: rec.month,
				year: rec.year,
				topic: rec.topic,
				status: status,
				video_id: rec.video_id,
				description: rec.description,
				attachments: attachments
			}
		end

		return recs, total
	end

	def get_all_attachments_participant rec
		rec.attachments_dataset.collect do |att|
			{
				id: att.id,
				name: att.name,
				type: att.type,
				link: "#{ENV['IMAGE_BASE_URL']}/uploads/attachments/#{att.name}"
			}
		end
	end

	def get_level_titles_participant page, limit, filters
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?

		ds = Level.dataset.not_deleted.where(published: true).order(:level)

		if filters
			filters.each do |filter|
				if filter['property'].downcase == "month"
					ds = ds.where(month: filter['value'].to_i)
				elsif filter['property'].downcase == 'year'
					ds = ds.where(year: filter['value'].to_i)
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.ilike(Sequel[:levels][:level], query_string)}
				end
			end
		end

		total = ds.count
		ds = ds.paginate(page, limit)
		status = nil
		show = true
		counter = 1
		recs = []
		forceshow = true
		prev_level_inactive = true
		prev_level_completed = true
		ds.collect do |rec|

			until rec[:level] == counter do
				recs.push({
					level_title_id: nil,
					level: counter,
					title: nil,
					show_level: false,
					description: nil,
					published: nil,
					status: 'inactive',
					materials: nil
					})
					counter = counter + 1
					forceshow=false
				end
				counter = counter + 1
			completed_quiz_response = Levelquizresponse.where(:level_title_id => rec[:id],:user_id => self.id, :completed => true).first
			progress_quiz_response = Levelquizresponse.where(:level_title_id => rec[:id],:user_id => self.id, :pending => true,:deleted_at => nil).last
			pending_quiz_response = Levelquizresponse.where(:level_title_id => rec[:id],:user_id => self.id).first

			if completed_quiz_response
				status = 'completed'
			elsif progress_quiz_response
				status = 'progress'
			elsif !pending_quiz_response
				status = 'pending'
			elsif rec[:published] == false
				status = 'inactive'
			end

			if !completed_quiz_response
				#! check for level completed with prev title
				Levelquizresponse.where(:user_id => self.id, :completed => true).each do |resp|
					if resp.level.level == rec[:level]
						status = 'completed'
						prev_level_completed = true
					end
				end

			end


			Level.where(:level => rec[:level]-1).each do |prevlevel|
				if prevlevel[:published] == false
					prev_level_inactive = true
				else
					prev_level_inactive = false
				end

			end

			# if rec[:attempted] == true and quiz_response
			# 	status = 'completed'
			# elsif rec[:attempted] == true and !quiz_response
			# 	status = 'progress'
			# elsif rec[:attempted] == false and !quiz_response
			# 	status = 'pending'
			# elsif
			# end
			show_level = false
			if status == 'completed' or status == 'progress'
				if status == 'completed' and !completed_quiz_response
				# * level completed for prev topic
					show_level = false
					forceshow = false
				elsif status == 'completed'
					forceshow = true
				end

				if forceshow
					show_level = true
				end

				if status == 'progress' and progress_quiz_response
					forceshow = false
					show_level = true
					prev_level_completed = false

				end
				if status == 'progress'

					forceshow = false
				end
			elsif status == 'pending' and show and forceshow

				show_level = true
				show = false
			elsif status == 'pending' and show and !forceshow and prev_level_inactive

				# * prev level isinactive and the current level is pending - show level -false
				show_level = false
				show = false
			elsif status == 'pending' and show and !forceshow and prev_level_completed

				show_level = true
				show = false

			elsif status == 'pending' and show and !forceshow and pending_quiz_response.nil?
				# * level 1 in progress and further levels pending -showlevel -false
				show_level = false

			elsif status == 'pending' and show and !forceshow
				# * level 1 in completed and next level pending -showlevel -true

				show_level = true
				show = false


			end

			materials = self.get_all_materials_participant(rec)
			recs.push({
				level_title_id: rec.id,
				level: rec.level,
				title: rec.title,
				show_level:show_level,
				description: rec.description,
				published: rec.published,
				status: status,
				materials: materials
			})

		end

		return recs, total
	end

	def get_all_materials_participant rec
		show = true
		rec.material_dataset.collect do |att|
			video_id = nil
			resume = nil
			material_counter = DB[:material_counter].where(:user_id => self.id,:material_id => att.id).first

			if material_counter
				if material_counter[:resume_counter]
					resume  = material_counter[:resume_counter]
				end
			end

			if att.material_type == "video"
				video_id = att.material.to_i
			else
				link = "#{ENV['IMAGE_BASE_URL']}/uploads/materials/#{att.material}"
			end

			active = material_counter.nil? ? false: material_counter[:active]

			if active
				show_material = true;
			elsif !active and show
				show_material = true;
				show = false
			else
				show_material = false;
			end


			resume= resume.to_i.to_f
			if !resume.nil?
				if resume>60
					resume_time= resume/60
					resume_time = resume_time.round(2)
					timeCalc=resume_time.to_s.split('.')
					resume_time = timeCalc[0]+'m'+(timeCalc[1].to_i*0.6).to_i.to_s+'s'
					# p
				else
					resume_time='0m'+(resume).to_i.to_s+'s'
				end
			else
				resume_time='0m0s'
			end

			{
				id: att.id,
				name: att.material,
				type: att.material_type,
				link: link.nil? ? nil: link,
				video_id: video_id.nil? ? nil: "https://player.vimeo.com/video/"+video_id.to_s,
				active: active,
				show: show_material,
				video_resume: resume_time
			}
		end
	end

	def submit_answers data, topic
		correct_answer = wrong_answer = 0
		msg = ''
		wrong_attempt = []
		quiz_points = 50

		if topic.attempted == false
			topic.update(
				attempted: true
			)
		end

		topic.add_quiz_response(
			topic_id: topic.id,
			response: data[:rec],
			user_id: self.id
		)


		data[:rec].each do |rec|
			que = topic.questions_dataset.not_deleted.where(id: rec[:question_id]).first
			if rec[:answer] == que.correct
				correct_answer += 1
			else
				wrong_answer += 1
				wrong_attempt.push({
					question_id: que[:id],
					question: que[:question],
					count: rec[:count]
				})
			end
		end

		if data[:rec].length == correct_answer
			msg += "Congratulations..!"

			point = self.point
			code = SecureRandom.hex(4).upcase

			self.add_claim(
				topic_id: topic.id,
				total_points: quiz_points,
				type: 'learn and earn',
				code: code
			)

			self.quiz_response.last.update(
				completed: true
			)

			self.quiz_response.each do |rec|
				if rec[:topic_id] == topic.id and rec[:pending] == true
					rec.soft_delete
				end
			end

			if point.nil?
				point = Point.new(
					user_id: self.id,
					earned: quiz_points
				)
				point.save
			else
				total_points = point.earned + quiz_points
				point.update(earned: total_points)
			end

			send_sms_quiz_complete self, topic.topic
		else
			self.quiz_response.last.update(
				pending: true
			)


			msg += "Try Again"
			send_sms_quiz_attempt self, topic.topic
		end

		{
			message: msg,
			correct: correct_answer,
			wrong: wrong_answer,
			wrong_attempt: wrong_attempt,
		}
	end

	def get_total_pool_points page, limit, filters

		ds = self.subordinates_dataset

		if filters
			filters.each do |filter|
				if filter['property'] == 'query'
					query_string = "%#{filter['value'].downcase.to_s}%"
					ds = ds.where(Sequel.like(Sequel.function(:lower, :name), query_string))
				end
			end
		end
		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rsa|
			cart_points = 0
			balance = 0
			id = 0
			earned = 0
			redeemed = 0
			total_lne_points = 0
			total_level_points = 0
			total_coupon_points = 0
			total_upload_points = 0
			total_upload_deducted_points = 0

			if !rsa.point.nil?
				cart_points = rsa.get_cart_points
				balance = rsa.point.earned - (rsa.point.redeemed + cart_points)
				id = rsa.point.id
				earned = rsa.point.earned
			end


			rsa.claims.each do |row|
				if row[:type] == 'learn and earn'
					total_lne_points += row[:total_points]
				elsif row[:type] == 'coupon'
					total_coupon_points += row[:total_points].to_i
				elsif row[:type] == 'levels'
					total_level_points += row[:total_points].to_i
				elsif row[:type] == 'upload points'
					total_upload_points += row[:total_points].to_i
					if row[:points_debited] > 0
						total_upload_deducted_points += row[:points_debited].to_i
					end

				end
			end
			{
				id:rsa[:id],
				name: rsa[:name],
				earned: earned,
				# total_lne_points: total_lne_points,
				# total_level_points: total_level_points,
				total_coupon_points: total_coupon_points,
				total_upload_points: total_upload_points,
				total_upload_deducted_points: total_upload_deducted_points.nil? ? nil : total_upload_deducted_points

			}
		end
		return recs,total

	end

	def get_associate_rsa page, limit, filters

		ds = self.subordinates_dataset

		if filters
			filters.each do |filter|
				if filter['property'] == 'query'
					query_string = "%#{filter['value'].downcase.to_s}%"
					ds = ds.where{Sequel.like(Sequel.function(:lower, :mobile), query_string)| Sequel.like(Sequel.function(:lower, :name), query_string)}
				end
			end
		end
		total = ds.count
		ds = ds.paginate(page, limit)

		recs = ds.collect do |rsa|
			{
				name: rsa[:name],
				mobile: rsa[:mobile]

			}
		end
		return recs,total

	end

	def get_dealer_quiz_status page, limit, filters
		topic_ds = month = year = nil
		today = Date.today
		recs = []


		if !filters
			filters = [{"property"=>"month", "value"=>"04"},{"property" => "year", "value" => today.year}]
		end

		# all_ds = self.subordinates_dataset.select(:name,:mobile,:id)
		if filters
			filters.each do |filter|
				if filter['property'] == "month"
					month = Date.new(today.year,filter['value'].to_i).month
					topic_ds = Topic.dataset.where(:month => filter['value'].to_i)

				end
			end
		end


		if month > 3
			year = Date.new(today.year,4)
		else
			year = Date.new(today.year,4).prev_year()
		end

		if topic_ds.count == 0

			error_message = "No Topics and users found"
			recs.push(
				{
					pending: [],
					pending_total: 0,
					completed: [],
					completed_total:0,
					error_message: error_message
				}
			)

		else


			all_ds = self.subordinates_dataset

			attempted_ds = topic_ds.join(:quiz_response, :topic_id => Sequel[:topics][:id])
			attempted_ds = attempted_ds.select(
				:user_id,
				:topic_id,
				:month,
				:year
			)
			attempted_ds = attempted_ds.group(:user_id, :topic_id, :month, :year)


			not_attempted_ds = all_ds.select(:id).exclude(:id => attempted_ds.select(:user_id))

			completed_attempted = topic_ds.join(:quiz_response, :topic_id => Sequel[:topics][:id],:completed => true)
			completed_attempted = completed_attempted.select(
										:user_id,
										:topic_id
									)


			pending_ds = attempted_ds.exclude(:user_id => completed_attempted.select(:user_id))

			final_pending_ds = not_attempted_ds.union(pending_ds.select(:user_id))

			final_pending_ds = Participant.join(final_pending_ds,:id => Sequel[:users][:id])





			completed_ds = Topic.dataset
			completed_ds = completed_ds.join(:quiz_response,:topic_id => Sequel[:topics][:id],:completed => true)
			completed_ds = completed_ds.join(all_ds,:id => Sequel[:quiz_response][:user_id])
			completed_ds = completed_ds.select(
				Sequel[:quiz_response][:user_id],
				Sequel[:topics][:month],
				Sequel[:topics][:year],
				[:name],
				[:mobile],
				Sequel[:quiz_response][:topic_id]
			)
			completed_ds = completed_ds.group(Sequel[:quiz_response][:user_id],Sequel[:topics][:month],Sequel[:topics][:year],[:name],[:mobile],Sequel[:quiz_response][:topic_id])
			if filters
				filters.each do |filter|
					if filter['property'] == "month"
						completed_ds = completed_ds.where(Sequel[:topics][:month] => filter['value'].to_i)
						pending_ds = pending_ds.where(:month => filter['value'])
					elsif filter['property'] == 'year'
						ds = ds.where(Sequel[:topics][:year] => filter['value'])
					end
				end
			end

			pending = final_pending_ds.collect do |pending|
				{
					name: pending[:name],
					mobile: pending[:mobile],
					month: month,
					year: year
				}
			end

			completed = completed_ds.collect do |completed|
				{
					name: completed[:name],
					mobile: completed[:mobile],
					month: completed[:month],
					year: completed[:year]
				}
			end
			recs.push(
				{
					pending: pending,
					pending_total: final_pending_ds.count,
					completed: completed,
					completed_total: completed_ds.count,
				}
			)

		end
		return recs

	end

	def submit_levels_answers data, level_title
		correct_answer = wrong_answer = 0
		msg = ''
		wrong_attempt = []
		level_quiz_points = level_title.points

		level_quiz_response = Levelquizresponse.where(:level_title_id => level_title.id,:user_id => self.id ).first

		level_title.add_level_quizresponse(
			response: data[:rec],
			level_title_id: level_title.id,
			user_id: self.id,
			attempted: true
		)


		data[:rec].each do |rec|
			que = level_title.levelquestions_dataset.not_deleted.where(id: rec[:question_id]).first
			if rec[:answer] == que.correct
				correct_answer += 1
			else
				wrong_answer += 1
				wrong_attempt.push({
					question_id: que[:id],
					question: que[:question],
					count: rec[:count]
				})
			end
		end

		if data[:rec].length == correct_answer
			msg += "Congratulations..!"

			point = self.point
			code = SecureRandom.hex(4).upcase

			self.add_claim(
				level_title_id: level_title.id,
				total_points: level_quiz_points,
				type: 'levels',
				code: code
			)

			self.leveluserresponses.last.update(
				completed: true
			)

			self.leveluserresponses.each do |rec|
				if rec[:level_title_id] == level_title.id and rec[:pending] == true
					rec.soft_delete
				end
			end

			if point.nil?
				point = Point.new(
					user_id: self.id,
					earned: level_quiz_points
				)
				point.save
			else
				total_points = point.earned + level_quiz_points
				point.update(earned: total_points)
			end

			completion_date = Date.today.strftime("%d-%m-%Y")

			#* certificate generation

			certificate_root = File.expand_path(File.join(File.dirname(__FILE__),'..','..','public','uploads','certificates'))

			root = File.expand_path(File.join(File.dirname(__FILE__), '..','htmltopng'))

			if !RUBY_PLATFORM.downcase.include?("linux") # windows
				wkhtmltox_exe = File.expand_path(File.join(root, 'wkhtmltox', 'bin', 'wkhtmltoimage.exe'))
				IMGKit.configure do |config|
					config.wkhtmltoimage = wkhtmltox_exe
				end
			end

			html_dir = File.expand_path(File.join(root, 'html'))

			img1 = File.expand_path(File.join(html_dir, '1.png'))
			img2 = File.expand_path(File.join(html_dir, '2.png'))
			img3 = File.expand_path(File.join(html_dir, '3.png'))

			output_dir = File.expand_path(File.join(root, 'output'))
			input_file = File.expand_path(File.join(html_dir, 'input.html'))
			css_file = File.expand_path(File.join(html_dir, 'main.css'))
			# js_file = File.expand_path(File.join(html_dir, 'main.js'))
			user_name =  self.name.gsub(/\s/,'_')

			output_file = File.expand_path(File.join(certificate_root, "LVL#{level_title.level}_#{level_title.id}_#{user_name}.png"))
			filename = "LVL#{level_title.level}_#{level_title.id}_#{user_name}.png"

			html = File.read input_file

			html =  html.gsub('XXXX', self.name)
			html =  html.gsub('XX', level_title.level.to_s)
			html =  html.gsub('altdate', completion_date)
			html =  html.gsub('img1', img1)
			html =  html.gsub('img2', img2)
			html =  html.gsub('img3', img3)


			kit = IMGKit.new(html, :quality => 50)
			kit.stylesheets << css_file
			# kit.javascripts << js_file

			img = kit.to_img

			# file = kit.to_file('/path/to/save/file.jpg')
			file = kit.to_file(output_file)

			# filename =  File.basename(output_file)


			Certificate.create(
				user_id: self.id,
				level: level_title.level,
				level_title_id: level_title.id,
				certificate: filename
			)


			if !self.email.to_s.empty?
				email_quiz_certificate self, level_title, completion_date, filename
			end
		else

			self.leveluserresponses.last.update(
				pending: true
			)

			msg += "Try Again"
			# send_sms_quiz_attempt self, level_title
		end

		{
			message: msg,
			correct: correct_answer,
			wrong: wrong_answer,
			wrong_attempt: wrong_attempt,
		}
	end

	def submit_material_counter data, material
		DB.transaction do


			existed_material = Materialcounter.where(:user_id => self.id,:material_id => data[:material_id]).first


			if data[:material_type] == 'pdf'
				# raise "You have already read this material"  if existed_material
				if !existed_material
					Materialcounter.create(
						user_id: self.id,
						material_id: data[:material_id],
						active: true
					)
				end
			else

				if data[:completed] == true
					if !existed_material
						Materialcounter.create(
							user_id: self.id,
							material_id: data[:material_id],
							resume_counter: 0,
							active: true
						)
					else
						existed_material.update(
							resume_counter: 0,
							active: true
						)
					end
				else
					if !existed_material
						Materialcounter.create(
							user_id: self.id,
							material_id: data[:material_id],
							resume_counter: data[:resume_min],
						)
					else
						existed_material.update(
							resume_counter: data[:resume_min]
						)
					end
				end
			end
		end
	end

	def get_all_certificate
		self.certificates_dataset.collect do |rec|
			level = Level.dataset.where(:id => rec.level_title_id).first

			certificate_root = File.expand_path(File.join(File.dirname(__FILE__),'..','..','public','uploads','certificates'))
			fullfilepath = File.expand_path(File.join(certificate_root, "#{rec.certificate}"))

			base64Data = Base64.encode64(File.open(fullfilepath, 'rb') {|file| file.read })
			{
				id:rec.id,
				user_id:rec.user_id,
				level:rec.level,
				level_title: level.title,
				link: "#{ENV['IMAGE_BASE_URL']}/uploads/certificates/#{rec.certificate}",
				base64: base64Data
			}
		end
	end

	def submit_title_attempt data, level_title

		quiz_response = Levelquizresponse.where(:level_title_id => level_title[:id],:attempted => true).first

		DB.transaction do

			if quiz_response
				quiz_response.update(
					attempted: true,
					pending: true
				)

			else

				level_title.add_level_quizresponse(
					level_title_id: level_title[:id],
					attempted: true,
					pending: true,
					user_id: self.id
				)
			end
		end
		# p level_title
	end

	def submit_customer_number data
		feedback = Feedback.where(user_id: self.id, customer_mobile: data[:customer_mobile].to_s).first
		raise "30 days not yet completed" if !feedback.nil? and feedback[:created_at] >= Time.now-30.days

		if feedback.nil?
			feedback = Feedback.create(
			user_id: self.id,
			customer_mobile: data[:customer_mobile]
			)

			send_sms_from_rsa_to_customer_requesting_feedback feedback.customer_mobile
		end
	end

	# * ============================================================================= #
	# *  - - - - - - Common Module - - - - - -   #
	# * ============================================================================= #

	def earnpoints_history start, limit, filters, sorter ,type
		ds = DB[:claims].where( Sequel[:claims][:deleted_at] => nil )
		ds = ds.where(user_id:self.id)
		from_date = nil
		to_date = nil
		filter_type=nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'type' and !filter['value'].nil?
					ds = ds.where(:type => filter['value'].downcase.to_s)
				elsif filter['property'] == 'from' and !filter['value'].nil?
					from_date = (Date.parse filter['value']).to_time
				elsif filter['property'] == 'to' and !filter['value'].nil?
					to_date = (Date.parse filter['value']).to_time
					to_date = to_date + (24 * 60 * 60)
				elsif filter['property'] == 'code'
					query_string = "#{filter['value'].to_s.downcase}%"
					# ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
					ds = ds.where{Sequel.ilike(Sequel[:claims][:code], query_string)}
				else
					# ds = ds.where(filter['property'].to_sym => filter['value'])
					query_string = "#{filter['value'].to_s.upcase}%"
					ds = ds.where(Sequel.like(filter['property'].to_sym, query_string))
				end
			end
		end

		if from_date and to_date
			ds = ds.where([:created_at] => from_date..to_date)
		end

		if sorter
			if sorter['property'] == 'points'
				ds = ds.order(:total_points)

				if sorter['direction'] == 'DESC'
					ds = ds.reverse
				end
			end
		end


		total = ds.count
		salesvalue=0
		recs = []
		topic = nil
		ds.drop(start).each_with_index do |item, ind|
			if item[:type] == 'learn and earn'
				topic = Topic.where(id: item[:topic_id]).first
			end

			if item[:total_points] == 0
				points =  "-" + item[:points_debited].to_s
			else
				points = "+" + item[:total_points].to_s
			end

			break if ind > limit

				recs.push({
					type: item[:type].capitalize,
					code: item[:code],
					status: item[:status],
					total_points:points,
					date: item[:created_at].iso8601,
					month: topic.nil? ? nil:topic.month,
					year: topic.nil? ? nil:topic.year
				})
		end
		return recs, total
	end
end

class ParticipantDetail < Sequel::Model(DB[:participant_details])
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :User


	def validate
		super
		validates_presence [:store_name]
	end
end #Permission

class Permission <  Sequel::Model(DB[:permissions])
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

	def validate
		super
		validates_includes ['ph', 'cso', 'dl', 'rsa'], :role_name, :message => 'is invalid'
	end

	def before_create
		super
		if self.role_name == 'dl'
			self.refer = true
		elsif self.role_name == 'rsa'
			self.pointsearn = true
			self.claim = true
			self.cart = true
			self.redemption = true
		end
	end

end #Permission

class Address < Sequel::Model(DB[:addresses])
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

	many_to_one		:city,
					:key	=> :city_id,
					:class	=> :City

	many_to_one		:state,
					:key	=> :state_id,
					:class	=> :State

	def validate
		super
		validates_presence [:name, :mobile, :address1, :city_id, :state_id, :pincode]
	end
end #Address

class Point < Sequel::Model(DB[:points].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

end #Point

class Claim < Sequel::Model(DB[:claims].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:claimant,
					:key	=> :user_id,
					:class	=> :Participant

	many_to_one		:topic,
					:key	=> :topic_id,
					:class	=> :Topic



	def validate
		super
		validates_presence [:type, :code]
		validates_presence [:total_points] if !new?
	end

end #Claim

class CartItem < Sequel::Model(DB[:cartitems])
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

	many_to_one		:reward,
					:key	=> :reward_id,
					:class	=> :Reward

	def before_create
		super
		item_reward_points = self.quantity * self.reward.points
		raise 'Insufficient points' if !participant.point
		balance_points = participant.point.earned - participant.point.redeemed - participant.get_cart_points

		raise 'Insufficient points' if item_reward_points > balance_points
	end

	def before_update
		super
		remaining_item_points = participant.cartitems_dataset.not_deleted.collect do |item|
			next if item.id == self.id
			item.quantity * item.reward.points
		end.compact.sum

		item_reward_points = self.quantity * self.reward.points
		balance_points = participant.point.earned - participant.point.redeemed - remaining_item_points
		raise 'Insufficient points' if item_reward_points > balance_points
	end
end #CartItem

class Order < Sequel::Model(DB[:orders].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant


	one_to_many     :items,
					:key    =>  :order_id,
					:class  =>  :OrderItem


	def get_details

		items.collect do |item|

			{
				sub_order_number:item.suborder_number,
				name: item.name,
				code: item.code,
				description: item.description,
				quantity: item.quantity,
				points: item.points,
				category: item.category_name,
				subcategory: item.sub_category_name,
				status: item.status,
				dispatch_courier: item.dispatch_courier,
				dispatch_date: item.dispatch_date,
				delivery_date: item.delivery_date,
				dispatch_awb_num: item.dispatch_awb_num,
				remarks: item.remarks
			}
		end
	end

end

class OrderItem < Sequel::Model(DB[:orderitems].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

	many_to_one		:order,
					:key	=> :order_id,
					:class	=> :Order

	def validate
		super
		validates_includes [
			'canceled',
			'redeemed',
			'dispatched',
			'delivered'
		], :status, :message => 'is invalid'

	end

end

class Referral < Sequel::Model(DB[:referrals])
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

end

class Product < Sequel::Model(DB[:products].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	one_to_many		:coupons,
					:key	=> :product_id,
					:class	=> :Product

	def validate
		super
		validates_presence [:material, :points]
	end

end

class Coupon < Sequel::Model(DB[:coupons].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

	many_to_one		:product,
					:key	=> :product_id,
					:class	=> :Product


	def validate
		super
		validates_presence [:material, :serial_no]
	end
end

class Knowledge_bank < Sequel::Model(DB[:knowledge_banks])
	plugin :validation_helpers
	plugin :paranoid

	def validate
		super
		validates_presence [:room, :weight, :material, :firmness, :priority, :budget, :old_mattress, :thickness, :collection, :product]
	end

	def self.mattress data

		answer1 = data[:answer1].to_s.downcase
		answer2 = data[:answer2].to_s.downcase
		answer3 = data[:answer3].to_s.downcase
		answer4 = data[:answer4].to_s.downcase
		answer5 = data[:answer5].to_s.downcase
		answer6 = data[:answer6].to_s.downcase
		answer7 = data[:answer7].to_s.downcase

		if answer1.empty? or
			answer2.empty? or
			answer3.empty? or
			answer4.empty? or
			answer5.empty? or
			answer6.empty? or
			answer7.empty?

			raise "Please answer all the questions"
		end

		ds = self.
		where(
			(Sequel.ilike(:weight, answer1)) &
			(Sequel.ilike(:material, answer2)) &
			(Sequel.ilike( :room, answer3)) &
			(Sequel.ilike( :old_mattress, answer4)) &
			(Sequel.ilike( :firmness, answer5)) &
			(Sequel.ilike( :priority, answer6)) &
			(Sequel.ilike( :budget, answer7))
		)

		ds.collect do |record|
			{
				id: record.id,
				weight: record.weight,
				room: record.room,
				material: record.material,
				firmness: record.firmness,
				priority: record.priority,
				budget: record.budget,
				old_mattress: record.old_mattress,
				thickness: record.thickness,
				collection: record.collection,
				product: record.product
			}
		end
	end
end

class Topic < Sequel::Model(DB[:topics].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	def validate
		super
		validates_presence [:month, :year, :topic]
	end

	one_to_many		:questions,
					:key    =>	 :topic_id,
					:class	=>	 :Question

	one_to_many		:claims,
					:key    =>	 :topic_id,
					:class	=>	 :Claim

	one_to_many		:attachments,
					:key    =>	 :topic_id,
					:class	=>	 :Attachments

	one_to_many		:quiz_response,
					:key    =>	 :topic_id,
					:class	=>	 :Quizresponse


	def get_all_question
		questions_dataset.not_deleted.collect do |rec|
			{
				id: rec.id,
				question: rec.question,
				correct: rec.correct,
				options: rec.options
			}
		end
	end

	def get_all_question_partcipant
		count = 0
		questions_dataset.not_deleted.collect do |rec|
			count += 1
			{
				id: rec.id,
				question: rec.question,
				options: rec.options,
				count:count
			}
		end
	end
end

class Attachments < Sequel::Model(DB[:attachments])
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:topic,
					:key	=>	:topic_id,
					:class	=>	:Topic
end

class Question < Sequel::Model(DB[:questions])
	plugin :validation_helpers
	plugin :paranoid
	plugin	:serialization, :json, :options

	def validate
		super
		validates_presence [:question, :correct]
	end
	# one_to_many		:options,
	# 				:key    =>	 :question_id,
	# 				:class	=>	 :Option

	many_to_one		:topic,
					:key	=>	:topic_id,
					:class	=>	:Topic

end

class Quizresponse < Sequel::Model(DB[:quiz_response])
	plugin	:validation_helpers
	plugin	:paranoid
	plugin	:serialization,  :json,  :response

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant



end

class Level < Sequel::Model(DB[:levels].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	def validate
		super
		validates_presence [:title, :description]
	end


	one_to_many		:material,
					:key	=> :level_title_id,
					:class	=> :Material

	one_to_many		:levelquestions,
					:key    =>	 :level_title_id,
					:class	=>	 :Levelquestion

	one_to_many		:level_quizresponses,
					:key    =>	 :level_title_id,
					:class	=>	 :Levelquizresponse


	def get_all_levels_question
		levelquestions_dataset.not_deleted.collect do |rec|
			{
				id: rec.id,
				question: rec.question,
				correct: rec.correct,
				options: rec.options
			}
		end
	end

	def get_all_levels_question_partcipant
		count = 0
		levelquestions_dataset.not_deleted.collect do |rec|
			count += 1
			{
				id: rec.id,
				question: rec.question,
				options: rec.options,
				count:count
			}
		end
	end
end

class Material < Sequel::Model(DB[:materials])
	plugin :paranoid

	many_to_one		:level,
					:key	=> :level_title_id,
					:class	=> :Level
end

class Levelquestion < Sequel::Model(DB[:levels_questions])
	plugin :validation_helpers
	plugin :paranoid
	plugin	:serialization, :json, :options

	def validate
		super
		validates_presence [:question, :correct]
	end

	many_to_one		:level,
					:key	=>	:level_title_id,
					:class	=>	:Level

end

class Levelquizresponse < Sequel::Model(DB[:levels_quizresponse])
	plugin	:validation_helpers
	plugin	:paranoid
	plugin	:serialization,  :json,  :response

	many_to_one		:level,
					:key	=> :level_title_id,
					:class	=> :Level


	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant


end

class Materialcounter < Sequel::Model(DB[:material_counter])
	plugin :paranoid

	# many_to_one		:level,
	# 				:key	=> :level_title_id,
	# 				:class	=> :Level
end

class Certificate  < Sequel::Model(DB[:certificates])

	# one_through_one 		:participant,
	# 				:key	=> :id,
	# 				:class	=> :Participant

	# many_to_many	:participants,
	# 				:right_key	=> :user_id,
	# 				:left_key	=> :level_title_id,
	# 				:join_table	=> :certificates,
	# 				:class	=> :Level

	many_to_one		:participant,
					:key	=> :id,
					:class	=> :Participant

end


# * ============================================================================= #
# * Following code is for Catalogue - Common Module.  #
# * ============================================================================= #

class Category < Sequel::Model(DB[:reward_categories])
	plugin :validation_helpers
	plugin :paranoid

	one_to_many     :subcategories,
					:key    =>  :category_id,
					:class  =>  :SubCategory

	one_to_many     :rewards,
					:key    =>  :category_id,
					:class  =>  :Reward


	def self.get
		self.collect do |cat|
			{
				id: cat.id,
				name: cat.name,
				image:"#{ENV['IMAGE_BASE_URL']}/images/rewards/categories/#{cat.image}?#{Time.now.to_i}"
			}
		end
	end

	def get_subcategories
		subcategories.collect do |subcat|
			{
				id: subcat.id,
				name: subcat.name,
				category_id: subcat.category_id
			}
		end
	end

	def get_rewards page, limit, filters, sorter
		raise 'page is required' if page.nil? or page.to_i.zero?
		raise 'limit is required' if limit.nil? or limit.to_i.zero?
		ds = self.rewards_dataset.not_deleted.where(active: true)

		min_points = nil
		max_points = nil

		if filters
			filters.each do |filter|
				if filter['property'] == 'min_points'
					min_points = filter['value'].to_i
				elsif filter['property'] == 'max_points'
					max_points = filter['value'].to_i
				elsif filter['property'] == 'sub_category_id'
					ds = ds.where(filter['property'].to_sym => filter['value'])
				elsif filter['property'] == 'query'
					query_string = "%#{filter['value'].to_s}%"
					ds = ds.where{Sequel.ilike(Sequel[:rewards][:name], query_string) | Sequel.ilike(Sequel[:rewards][:code], query_string)}
				end
			end
		end

		if min_points and max_points
			ds = ds.where(points: min_points..max_points)
		end

		if sorter
			ds = ds.order(sorter['property'].to_sym)
			if sorter['direction'] == 'DESC'
				ds = ds.reverse
			end
		end

		total = ds.count

		ds = ds.paginate(page, limit)
		# y ds.all
		points=[]
		recs = ds.collect do |reward|
			points.push reward.points
			{
				id: reward.id,
				name: reward.name,
				model_number: reward.model_number,
				code: reward.code,
				brand: reward.brand,
				description: reward.description,
				image: reward.image.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/pics/#{reward.image}?#{Time.now.to_i}",
				thumbnail: reward.thumbnail.nil? ? nil : "#{ENV['IMAGE_BASE_URL']}/images/rewards/products/thumbs/#{reward.thumbnail}?#{Time.now.to_i}",
				points: reward.points,
				category_id: self.id,
				category_name: self.name,
				sub_category_id: reward.sub_category_id,
				# sub_category_name: reward.sub_category.name
			}
		end
		return recs, total, points.max, points.min
	end
end

class SubCategory < Sequel::Model(DB[:reward_sub_categories])
	plugin :validation_helpers
	plugin :paranoid

	one_to_many     :rewards,
					:key    =>  :sub_category_id,
					:class 	=> 	:Reward

	many_to_one		:category,
					:key	=> :category_id,
					:class	=> :Category

end

class Reward < Sequel::Model(DB[:rewards].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:category,
					:key	=> :category_id,
					:class	=> :Category

	many_to_one		:sub_category,
					:key	=> :sub_category_id,
					:class	=> :SubCategory
end

class ReportDownloadRequest < Sequel::Model(DB[:report_download_requests].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:helpdeskuser,
					:key	=> :user_id,
					:class	=> :HelpDeskUser


end # ReportDownloadRequest

class Feedback < Sequel::Model(DB[:feedback].extension(:pagination))
	plugin :validation_helpers
	plugin :paranoid

	many_to_one		:participant,
					:key	=> :user_id,
					:class	=> :Participant


end # Feedback
