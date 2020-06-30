%w(
	base64
	yaml
	securerandom
	fileutils
).each { |lib| require lib }

public_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'public'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'rewards', 'categories'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'rewards', 'products', 'pics'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'rewards', 'products', 'thumbs'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'gallery', 'products', 'pics'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads', 'gallery', 'products', 'thumbs'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'images', 'banners'))
FileUtils.mkdir_p File.expand_path(File.join(public_dir, 'uploads','reports'))


ENV['RACK_ENV'] = 'test' if ENV['RACK_ENV'].nil? or !ENV['RACK_ENV'].include? 'test'

require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

require_relative '../../app/routes'

$bangalore = City.where(name: 'Bangalore').first

def indifferent_data(data)
	case data
	when Hash
		hash = Hash.new{|h, k| h[k.to_s] if Symbol === k}
		data.each{|k, v| hash[k] = indifferent_data(v)}
		hash
	when Array
		data.map{|x| indifferent_data(x)}
	else
		data
	end
end

def create_helpdesk_user
	$hduser_email = 'helpdesktest@email.com'
	$hduser_password = 'password'

	hduser = HelpDeskUser.new
	hduser.set(
		role: 'h',
		email: $hduser_email,
		active: true,
	)
	hduser.save

	Device.create(
		password: $hduser_password,
		password_confirmation: $hduser_password,
		password_text: $hduser_password,
		user_id: hduser.id
	)

end

def create_participants_and_permissions

	#  ================================================
	#     Create CSO
	#  ================================================

	$mobile1 = '911234567899'
	$otp = '111111'
	$player_id = '121212'

	part1 = Participant.new(
		mobile: $mobile1,
		name: 'CSO 1',
		role: 'p',
		active: true
	)

	part1.permission.role_name = 'cso'
	part1.save
	$cso = part1

	part1_detail = ParticipantDetail.new(
		doa: '12/10/2000',
		dob: '17/12/1992',
		user_id: part1.id,
		doj: '12/10/2000',
		store_name: 'qwerty',
		experience: 2,
		qualification: 12,
		mother_tongue: 'Kannada'
	)

	part1.add_device(
		otp: $otp2,
		password: 'password',
		password_confirmation: 'password'
	)

	part1.add_address(
		name: 'BBB',
		mobile: $mobile1,
		address1: 'BBB 2',
		city_id: $bangalore.id,
		state_id: $bangalore.state.id,
		pincode: '3213222'
	)

	#  ================================================
	#     Create DEALER
	#  ================================================

	$mobile2 = '911234567898'

	part2 = Participant.new(
		mobile: $mobile2,
		name: 'dealer 1',
		role: 'p',
		active: true
	)

	part2.permission.role_name = 'dl'
	part2.save
	$dl = part2

	part2_detail = ParticipantDetail.new(
		doa: '12/10/2000',
		dob: '17/12/1992',
		user_id: part2.id,
		doj: '12/10/2000',
		store_name: 'asdfg',
		experience: 2,
		qualification: 12,
		mother_tongue: 'Kannada'
	)

	part2.add_device(
		otp: $otp,
		password: 'password',
		password_confirmation: 'password'
	)

	part2.add_address(
		name: 'BBB',
		mobile: $mobile2,
		address1: 'BBB 2',
		city_id: $bangalore.id,
		state_id: $bangalore.state.id,
		pincode: '3213222'
	)
	#  ================================================
	#     Create RSA
	#  ================================================

	$mobile3 = '911234567897'

	part3 = Participant.new(
		mobile: $mobile3,
		name: 'rsa 1',
		role: 'p',
		parent_id: part2.id,
		active: true
	)

	part3.permission.role_name = 'rsa'
	part3.save
	$participant_id = part3.id

	$rsa = part3

	part3_detail = ParticipantDetail.new(
		doa: '12/10/2000',
		dob: '17/12/1992',
		user_id: part3.id,
		doj: '12/10/2000',
		store_name: 'asdfg',
		experience: 2,
		qualification: 12,
		mother_tongue: 'Kannada'
	)

	part3.add_device(
		otp: $otp2,
		password: 'password',
		password_confirmation: 'password'
	)

	part3.add_address(
		name: 'BBB',
		mobile: $mobile3,
		address1: 'BBB 2',
		city_id: $bangalore.id,
		state_id: $bangalore.state.id,
		pincode: '3213222'
	)

	point = Point.new(
		user_id: part3.id,
		earned: 500,
		redeemed: 50
	)
	point.save

	claim = Claim.new(
		user_id: part3.id,
		type:'welcome',
		code:'CTRLD0001',
		total_points: 200,
	)
	claim.save

	$mobile4 = '911234567896'

	part4 = Participant.new(
		mobile: $mobile4,
		name: 'rsa 2',
		parent_id: part2.id,
		role: 'p',
		active: true
	)

	part4.permission.role_name = 'rsa'
	part4.save

	$rsa_2 = part4

	part4_detail = ParticipantDetail.new(
		doa: '12/10/2000',
		dob: '17/12/1992',
		user_id: part4.id,
		doj: '12/10/2000',
		store_name: 'asdfg',
		experience: 2,
		qualification: 12,
		mother_tongue: 'Kannada'
	)

	part4.add_device(
		otp: $otp2,
		password: 'password',
		password_confirmation: 'password'
	)

	part4.add_address(
		name: 'BBB',
		mobile: $mobile4,
		address1: 'BBB 2',
		city_id: $bangalore.id,
		state_id: $bangalore.state.id,
		pincode: '3213222'
	)
end


def create_helpdesk_request
	$help_dealer_request = HelpDeskRequest.create(
		type: 'sms',
		keyword: 'LND',
		participant_type: 'dealer',
		mobile: '123456789012',
		status: 'incomplete',
		name: 'dealer',
		address1: 'AAA',
		city_id: $bangalore.id,
		state_id: $bangalore.state.id,
		pincode: '123213',
		store_name: 'qwerty'
	)

	$help_rsa_request = HelpDeskRequest.create(
		type: 'sms',
		keyword: 'LND',
		participant_type: 'rsa',
		mobile: '123456789013',
		status: 'incomplete',
		name: 'RSA',
		address1: 'AAA',
		city_id: $bangalore.id,
		state_id: $bangalore.state.id,
		pincode: '123213',
		store_name: 'qwerty'

	)
end


def create_rewards
	$category_1 = Category.create(
		name: 'Aaa',
		image: 'https://picsum.photos/512/512/?random'
	)

	$sub_category_1 = $category_1.add_subcategory(
		name: 'BBB'
	)

	$reward_100 = Reward.create(
		name: 'Reward - 1',
		model_number: 'Z-100',
		code: 'ZZ-100',
		brand: 'ZZZZZZ',
		description: 'ZZ',
		image: 'https://picsum.photos/200/200/?random',
		thumbnail: 'https://picsum.photos/80/80/?random',
		points: 100,
		category_id: $category_1.id,
		sub_category_id: $sub_category_1.id,
		active: true
	)

	$reward_200 = Reward.create(
		name: 'Reward - 2',
		model_number: 'Z-200',
		code: 'ZZ-200',
		brand: 'ZZZZZZ',
		description: 'ZZ',
		image: 'https://picsum.photos/200/200/?random',
		thumbnail: 'https://picsum.photos/80/80/?random',
		points: 200,
		category_id: $category_1.id,
		sub_category_id: $sub_category_1.id,
		active: true
	)

	$reward_400 = Reward.create(
		name: 'Reward - 4',
		model_number: 'Z-400',
		code: 'ZZ-400',
		brand: 'PRESTIGE',
		description: 'ZZ',
		image: 'https://picsum.photos/200/200/?random',
		thumbnail: 'https://picsum.photos/80/80/?random',
		points: 400,
		category_id: $category_1.id,
		sub_category_id: $sub_category_1.id
	)

end

def create_product_and_coupons

	product1 = Product.create(
		material: 'ABC',
		description: 'bla bla bla',
		group: 'bla bla bla',
		measure: 'bla bla bla',
		points: 150
	)

	$coupon1_code = 'C123'
	$coupon2_code = 'A456'
	Coupon.create(
		serial_no: $coupon1_code,
		material: product1.material,
		product_id: product1.id,
	)

	Coupon.create(
		serial_no: $coupon2_code,
		material: product1.material,
		product_id: product1.id,
	)
end

def create_orders
	$order = Order.create(
		order_number: 'ELRNR0001',
		user_id: $participant_id,
		points: 40,
		num_items: 4,
		created_at: "2019-07-29T12:10:46+05:30",
		name: 'userone',
		mobile: '1234567890',
		address1: 'address1',
		address2: 'address2',
		city: 'Bangalore',
		state: 'Karnataka',
		pincode: "123456",
	)

	$order_item_1 = $order.add_item(
		quantity: 1,
		user_id: $participant_id,
		suborder_number: 'ELRNR0001-53',
		status: 'redeemed',
		name: 'Reward - 1',
		model_number: 'Z-100',
		code: 'ZZ-100',
		brand: 'ZZZZZZ',
		description: 'ZZ',
		image: '/images/rewards/products/pics/https://picsum.photos/200/200/?random',
		thumbnail: '/images/rewards/products/thumbs/https://picsum.photos/200/200/?random',
		points: 10,
		category_name: 'AAA',
		sub_category_name: 'BBB'
	)

	$order_item_2 = $order.add_item(
		quantity: 1,
		user_id: $participant_id,
		suborder_number: 'ELRNR0001-AB',
		status: 'dispatched',
		name: 'Reward - 1',
		model_number: 'Z-100',
		code: 'ZZ-100',
		brand: 'ZZZZZZ',
		description: 'ZZ',
		image: '/images/rewards/products/pics/https://picsum.photos/200/200/?random',
		thumbnail: '/images/rewards/products/thumbs/https://picsum.photos/200/200/?random',
		points: 10,
		category_name: 'AAA',
		sub_category_name: 'BBB'
	)

	$order_item_3 = $order.add_item(
		quantity: 1,
		user_id: $participant_id,
		suborder_number: 'ELRNR0001-90',
		status: 'delivered',
		name: 'Reward - 1',
		model_number: 'Z-100',
		code: 'ZZ-100',
		brand: 'ZZZZZZ',
		description: 'ZZ',
		image: '/images/rewards/products/pics/https://picsum.photos/200/200/?random',
		thumbnail: '/images/rewards/products/thumbs/https://picsum.photos/200/200/?random',
		points: 10,
		category_name: 'AAA',
		sub_category_name: 'BBB'
	)

	$order_item_4 = $order.add_item(
		quantity: 1,
		user_id: $participant_id,
		suborder_number: 'ELRNR0001-88',
		status: 'canceled',
		name: 'Reward - 1',
		model_number: 'Z-100',
		code: 'ZZ-100',
		brand: 'ZZZZZZ',
		description: 'ZZ',
		image: '/images/rewards/products/pics/https://picsum.photos/200/200/?random',
		thumbnail: '/images/rewards/products/thumbs/https://picsum.photos/200/200/?random',
		points: 10,
		category_name: 'AAA',
		sub_category_name: 'BBB'
	)
end

# Must use this class as the base class for your tests
class SequelTestCase < Test::Unit::TestCase
	def run(*args, &block)
		result = nil
		Sequel::Model.db.transaction(:rollback=>:always, :auto_savepoint=>true){result = super}
		result
	end
end