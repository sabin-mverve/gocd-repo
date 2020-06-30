require 'dotenv'

Dotenv.load
Dotenv.load ".env.#{ENV['RACK_ENV']}"

require 'bundler'
Bundler.require(:default)

require "securerandom"
require_relative 'server/seeder/production/states_cities_seeder'
require_relative 'server/seeder/production/product_master'
require_relative 'server/seeder/production/seed_mattress'
require_relative 'server/seeder/version_seeder'

models_full_path = File.expand_path(File.join(File.dirname(__FILE__), 'server', 'app', 'models.rb'))
require models_full_path

DB.transaction do
    seed_states_and_cities
    seed_products
	seed_mattress
	seed_version


    $bangalore = City.where(name: 'Bangalore').first

    # ============================================ #
                # Create a HelpDesk User #
    # ============================================ #

    hduser_obj =  HelpDeskUser.new(
        email: 'helpdesk@email.com',
        name: 'HelpDesk User',
        role: 'h',
        active: true
    )

    hduser_obj.save

    Device.create(
        password: 'password',
        password_confirmation: 'password',
        password_text: 'password',
        user_id: hduser_obj.id
    )

	puts "HelpDesk user created"

	hduser_obj =  HelpDeskUser.new(
		email: 'raksha@mobignosis.net',
		name: 'Raksha',
		role: 'h',
		active: true
	)

	hduser_obj.save

	Device.create(
		password: 'password',
		password_confirmation: 'password',
		password_text: 'password',
		user_id: hduser_obj.id
	)

	puts "HelpDesk user -raksha created"

	hduser_obj =  HelpDeskUser.new(
		email: 'mahesh@mverve.com',
		name: 'Mahesh',
		role: 'h',
		active: true
	)

	hduser_obj.save

	Device.create(
		password: 'password',
		password_confirmation: 'password',
		password_text: 'password',
		user_id: hduser_obj.id
	)

	puts "HelpDesk user -Mahesh created"

    hduser_obj1 =  HelpDeskUser.new(
        email: 'helpdeskelevatoz@email.com',
        name: 'HelpDesk User 2',
        role: 'h',
        active: true
    )

    hduser_obj1.save

    Device.create(
        password: 'password',
        password_confirmation: 'password',
        password_text: 'password',
        user_id: hduser_obj1.id
    )

    puts "HelpDesk user 2 created"

    # ============================================ #
                # Create RSA #
    # ============================================ #

	rsa1_mobile = '919191919191'
	otp = '111111'
    rsa1 = Participant.where(mobile: rsa1_mobile).first

    if !rsa1
        rsa1 = Participant.new(
            mobile: rsa1_mobile,
            name: 'RSA ',
            active: true,
            email: 'rsa@lnd.com',
            role: 'p'
        )
        rsa1.permission.role_name = 'rsa'
        rsa1.save

        rsa1_detail = ParticipantDetail.new(
            doa: '12/10/2000',
            dob: '17/12/1992',
            user_id: rsa1.id,
            doj: '12/10/2000',
            store_name: 'qwerty',
            experience: 2,
            qualification: 12,
            mother_tongue: 'Kannada'
        )

        rsa1.add_address(
            name: 'BBB',
            mobile: rsa1_mobile,
            address1: 'BBB 2',
            city_id: $bangalore.id,
            state_id: $bangalore.state.id,
            pincode: '3213222'
		)

		rsa1_detail.save
		rsa1.save
    end

    # ============================================ #
                # Create DEALERS #
    # ============================================ #

    dl1_mobile = '918181818181'
    dl1 = Participant.where(mobile: dl1_mobile).first

    if !dl1
        dl1 = Participant.new(
            mobile: dl1_mobile,
            name: 'DEALER1',
            active: true,
            email: 'dealer1@lnd.com',
            role: 'p'
        )
        dl1.permission.role_name = 'dl'
        dl1.save

        dl1.add_subordinate rsa1

        dl1_detail = ParticipantDetail.new(
            doa: '12/10/2000',
            dob: '17/12/1992',
            user_id: dl1.id,
            doj: '12/10/2000',
            store_name: 'qwerty',
            experience: 2,
            qualification: 12,
            mother_tongue: 'Kannada'
		)


        dl1.add_address(
            name: 'BBB',
            mobile: dl1_mobile,
            address1: 'BBB 2',
            city_id: $bangalore.id,
            state_id: $bangalore.state.id,
            pincode: '3213222'
		)

		dl1_detail.save
		dl1.save
    end

    # ============================================ #
                # Create CSO #
    # ============================================ #

    cso1_mobile = '917171717171'
    cso1 = Participant.where(mobile: cso1_mobile).first

    if !cso1
        cso1 = Participant.new(
            mobile: cso1_mobile,
            name: 'CSO1',
            active: true,
            email: 'cso1@lnd.com',
            role: 'p'
        )
        cso1.permission.role_name = 'cso'
        cso1.save
        cso1.add_subordinate dl1

        cso1_detail = ParticipantDetail.new(
            doa: '12/10/2000',
            dob: '17/12/1992',
            user_id: cso1.id,
            doj: '12/10/2000',
            store_name: 'qwerty',
            experience: 2,
            qualification: 12,
            mother_tongue: 'Kannada'
        )
    end

    puts "CSO Created"
	puts "RSA Created"

	cat1 = Category.create(
        name: 'Automobile',
        image: 'automobile.png'
    )

	subcat1 = cat1.add_subcategory(
        name: 'Cars',
	)

    reward1 = Reward.create(
        name: 'Popular Aluminium Pressure Cookers 12 Litre-10033',
        model_number: '10033',
        code: 'ZZ10000',
        brand: 'Prestige',
        description:'Lorem ipsum dolor sit amet, graeci ceteros expetendis ne sea. Nobis sententiae sit et. Per blandit lobortis an, usu ei mediocrem adolescens referrentur. Ne sit reque ,',
        image: 'el0001-a.png',
        points: 100,
        category_id: cat1.id,
        sub_category_id: subcat1.id
    )

    reward2 = Reward.create(
        name: 'Popular Aluminium Pressure Cookers 12 Litre-10033',
        model_number: '10200',
        code: 'ZZ10001',
        brand: 'Prestige',
        description:'Lorem ipsum dolor sit amet, graeci ceteros expetendis ne sea. Nobis sententiae sit et. Per blandit lobortis an, usu ei mediocrem adolescens referrentur. Ne sit reque ,',
        image: 'el0001-a.png',
        points: 1890,
        category_id: cat1.id,
        sub_category_id:  subcat1.id
    )

    reward3 = Reward.create(
        name: 'Omega Select Plus Omni Tawa 250 mm-30709',
        model_number: '30709',
        code: 'ZZ10002',
        brand: 'Prestige',
        description: 'Lorem ipsum dolor sit amet, graeci ceteros expetendis ne sea. Nobis sententiae sit et. Per blandit lobortis an, usu ei mediocrem adolescens referrentur. Ne sit reque ,',
        image: 'el0001-a.png',
        points: 8900,
        category_id: cat1.id,
        sub_category_id:  subcat1.id
    )

    reward4 = Reward.create(
        name: 'Omega Select Plus Omni Tawa 300 mm-30711',
        model_number: '30711',
        code: 'ZZ10003',
        brand: 'Prestige',
        description: 'Lorem ipsum dolor sit amet, graeci ceteros expetendis ne sea. Nobis sententiae sit et. Per blandit lobortis an, usu ei mediocrem adolescens referrentur. Ne sit reque ',
        image: 'el0001-a.png',
        points: 2245,
        category_id: cat1.id,
        sub_category_id:  subcat1.id
    )

	 # ============================================ #
                # Add a vimeo id #
	# ============================================ #


	# topic1 = Topic.create(
	# 	month: 01,
	# 	year: 2020,
	# 	topic: 'Topic with video testing',
	# 	description: 'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, graphic or web designs.',
	# 	video_id: '384703829'
	# )

	# topic1.save

	# topic2 = Topic.create(
	# 	month: 11,
	# 	year: 2019,
	# 	topic: 'Topic2 with video testing',
	# 	description: 'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, graphic or web designs.',
	# 	video_id: '384704695'
	# )

	# topic2.save


	# puts "Topics created"



end