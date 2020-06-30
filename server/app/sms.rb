require 'httparty'


# def send_sms_mobile_under_registration mobile
# 	raise 'mobile is required' if !mobile or mobile.to_s.empty?

# 	text = "Hi, Thank you for contacting Duroflex SKD, your #{mobile} is already in process we will contact you shortly for completing the registration– T&C Apply, Duroflex SKD."
# 	SMS.send_sms mobile, text
# end

# def send_sms_mobile_already_registered mobile
# 	raise 'mobile is required' if !mobile or mobile.to_s.empty?

# 	text = "Hi, your attempt to enroll #{mobile} mobile no. on Duroflex SKD program has failed, as this number is already registered on the program, for more details contact 1800-5729-496 T&C Apply, Duroflex SKD. "
# 	SMS.send_sms mobile, text
# end

def send_sms_mobile_successfully_registered user

	mobile = user.mobile
    raise 'mobile is required' if !mobile or mobile.to_s.empty?

    text = "Dear  #{user.name}, Welcome to CLASS. Download https://play.google.com/store/apps/details?id=com.domain.LND App from Play Store, and https://apps.apple.com/in/app/mattress-class/id1502978611 from App store, login using your registered mobile number.Your learning journey starts here. T&C Apply, CLASS."

	SMS.send_sms mobile, text
end

def send_sms_participant_login_otp mobile, otp
	raise 'mobile is required' if !mobile or mobile.to_s.empty?
	raise 'otp is required' if !otp or otp.to_s.empty?

	text = "Enter this OTP #{otp} to login to your CLASS mobile app - T&C Apply, CLASS"

	SMS.send_sms mobile, text
end

def send_sms_points_earn user, points, bal
    mobile = user.mobile
    raise 'mobile is required' if !mobile or mobile.to_s.empty?

    text = "Congratulations! Dear #{user.name}, you have earned #{points} points.  Your points balance is #{bal}. T&C Apply, CLASS"

	SMS.send_sms mobile, text
end

def send_sms_helpdesk_successful_checkout user, order_number, order
	mobile = user.mobile
    raise 'mobile is required' if !mobile or mobile.to_s.empty?

	balance_points = user.get_balance_points
	order_date =  order.created_at.strftime("%d-%m-%Y")

    text = "Dear #{user.name}, your redemption order no. #{order_number} for item #{order.name} has been placed on #{order_date}. Current points balance is #{balance_points}. T&C Apply, CLASS. "
	SMS.send_sms mobile, text
end


#order management

def send_sms_helpdesk_status_dispatched particpant, order

    mobile = particpant[:mobile]
	raise 'mobile is required' if !mobile or mobile.to_s.empty?

    text = "Dear #{particpant[:name]}, Your reward against your Order ID #{order[:suborder_number]} has been dispatchedhed to the registered address. Your tracking number is #{order[:dispatch_awb_num]} T&C Apply, Team CLASS"

	SMS.send_sms mobile, text
end

# def send_sms_helpdesk_status_redeemed particpant,mobile,order,balance_points
# 	raise 'mobile is required' if !mobile or mobile.to_s.empty?

# 	text = "Dear#{particpant[:name]}, Your redemption has been confirmed and your order ID is#{order[:suborder_number]}. You have #{balance_points} points in your account now. T&C Apply,  Duroflex SKD."
# 	SMS.send_sms mobile, text
# end

def send_sms_helpdesk_status_delivered particpant, order
    mobile = particpant[:mobile]
	raise 'mobile is required' if !mobile or mobile.to_s.empty?

    text = "Dear #{particpant[:name]}, Your reward against your Order ID #{order[:suborder_number]} has been delivered to the registered address. T&C Apply, Team CLASS"

	SMS.send_sms mobile, text
end

# def send_sms_helpdesk_status_canceled particpant,mobile,order
# 	raise 'mobile is required' if !mobile or mobile.to_s.empty?

# 	text = "Dear #{particpant[:name]}, Your Order ID #{order[:suborder_number]} has been cancelled. For further information please call on 18005729496. T&C Apply, Duroflex SKD."
# 	SMS.send_sms mobile, text
# end


# birthdays
def send_sms_participant_birthday mobile, name
	raise 'mobile is required' if !mobile or mobile.to_s.empty?

	text = "Dear #{name}, Team CLASS wishes you a Happy Birthday! May this year bring in good health & prosperity into your life. Regards, CLASS"
	SMS.send_sms mobile, text
end

#*========================================== anniversaries================================*#
def send_sms_participant_anniversary mobile, name
	raise 'mobile is required' if !mobile or mobile.to_s.empty?

	text = "Dear #{name}, Wishing you and your spouse a Happy Anniversary! We wish you a life filled with love and prosperity! Regards, CLASS"
	SMS.send_sms mobile, text
end

def send_sms_points_earned participant, points
	mobile = participant[:mobile]
	raise 'mobile is required' if !mobile or mobile.to_s.empty?
	balance = participant.get_balance_points
	text =  "Congratulations! Dear #{participant[:name]}, you have earned #{points} points.  Your points balance is #{balance}. T&C Apply, CLASS"
	SMS.send_sms mobile, text
end

def send_sms_quiz_attempt participant, topic
	mobile = participant[:mobile]
	raise 'mobile is required' if !mobile or mobile.to_s.empty?
	text = "Dear #{participant[:name]}, Thank you for participating in the quiz (#{topic}). Try unless you get succeed. All the best. Regards, Team CLASS"
	SMS.send_sms mobile, text
end

def send_sms_quiz_complete participant, topic
	mobile = participant[:mobile]
	raise 'mobile is required' if !mobile or mobile.to_s.empty?
	balance = participant.get_balance_points
	text = "Congratulations #{participant[:name]}, For completing the Quiz (#{topic}) You earn 50 points on completing the quiz. Your current point balance is #{balance}. Regards, Team CLASS"
	SMS.send_sms mobile, text
end


# *======================sending sms to customers===========================*#

def send_sms_from_rsa_to_customer_requesting_feedback customer_mobile
	raise 'mobile is required' if !customer_mobile or customer_mobile.to_s.empty?
	text = "Thank you for shopping with Centuary !! Hope you were happy with the Services provided by our Sales Associate. If Yes then please type Y and send it to 9123xxxxx98. If No then please type N and send it to 9123xxxxx98.Team Centuary"
	SMS.send_sms customer_mobile, text
end

def send_sms_more_than_once_in_a_month customer_mobile
	raise 'mobile is required' if !customer_mobile or customer_mobile.to_s.empty?
	text = "Sorry, you have exhausted your current limit to provide feedback. Please try again later. To check out other Centuary products please visit our website. https://www.centuaryindia.com/"
	SMS.send_sms customer_mobile, text
end

def send_sms_reply_for_invalid_format customer_mobile
	raise 'mobile is required' if !customer_mobile or customer_mobile.to_s.empty?
	text = "Sorry, this is an invalid response please try again by replying ‘Y’ if you are happy with the Services provided by our Sales Associate. If not then please reply by typing ‘N’ and send it to 9123xxxxx98. Team Centuary"
	SMS.send_sms customer_mobile, text
end

def send_sms_for_unknown_number customer_mobile
	raise 'mobile is required' if !customer_mobile or customer_mobile.to_s.empty?
	text = "This service is not available on your mobile number please use the number on which you have received the message"
	SMS.send_sms customer_mobile, text
end

#*================================================================================*#

def send_sms_reply_for_yes  participant, points
	raise 'mobile is required' if !participant[:mobile] or participant[:mobile].to_s.empty?
	text = "Congratulations #{participant[:name]}!!, You have earned 5 points for the feedback received from customer. Keep up the good work and keep earning points!! Your current point balance is #{points}. Regards, Team CLASS"
	SMS.send_sms participant[:mobile], text
end

def send_sms_reply_for_no participant
	raise 'mobile is required' if !participant[:mobile] or participant[:mobile].to_s.empty?
	text = "Sorry, the customer was not happy with your services. Please keep working hard and better luck next time. Team Centuary"
	SMS.send_sms participant[:mobile], text
end

module SMS
	def self.send_sms mobile, text
		begin
			if ENV['RACK_ENV'] == 'production' or ENV['RACK_ENV'] == 'staging'
				username = 'elevatozhtp2'
				password = 'elev0956'
				from = 'ELVTOZ'
				to = mobile
				text = text

				params = {
					username: username,
					password: password,
					to: to,
					from: from,
					text: text
				}

				enc_params = URI.encode_www_form params

				url = 'http://www.myvaluefirst.com/smpp/sendsms'
				url_with_params = url + '?' + enc_params

				resp = HTTParty.post( url_with_params )

				if defined? LOGGER
					LOGGER.info(url_with_params)
					LOGGER.info(resp)
				end
			elsif ENV['RACK_ENV'] != 'alltest'
				puts "Sending SMS - #{mobile}"
				puts text
			end

		rescue Exception => e
			raise "sms error occurred: #{e.class} - #{e.message}"
		end
	end
end