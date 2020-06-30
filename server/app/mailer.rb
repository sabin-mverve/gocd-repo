require 'sparkpost'
require 'imgkit'

ENV['SPARKPOST_API_KEY'] = "66e19c7036ecb4c9aa2ab06d0404b97e70f06647"


def email_quiz_certificate user, level_title, completion_date, filename


	# email_to = user.email
	email_to = []
	email_to.push user.email

    subject = "CENTUARY_CLASS Program_Level #{level_title.level} Completed"

    body = "Congratulations #{user.name} on successfully completing the Level #{level_title.level} <br>
	Attached is the Certificate of Completion.<br>
	In addition to that we have credited #{level_title.points} points against your registered number #{user.mobile}.<br>
	<br>
	<br>
	Keep Learning and Earning with CLASS.<br>
	<br>
	<br>
	Sincerely<br>
	CLASS Admin<br>
	"
    Email.send_email_certificate email_to, subject, body, filename
end

def send_email_request_download_success helpdeskuser, reportrequest

	email_to = []
	email_to.push helpdeskuser.email

    subject = "Requested Report"


	body = "Dear #{helpdeskuser.name},
	<br/>
	<br/>
	Your report #{reportrequest.type} request has been executed successfully. Please log into the Helpdesk app to download the report.
	<br/>
	<br/>
	<br/>
	<br/>
	Warm Regards<br/>
	"

    Email.send_email email_to, subject, body

end

def send_email_request_download_failure helpdeskuser, reportrequest

	email_to = []
	email_to.push helpdeskuser.email

    subject = "Requested Report"


	content = "Dear #{helpdeskuser.name},
	<br/>
	<br/>
	Your report #{reportrequest.type} request has failed. Please log into the Helpdesk app and try again.
	<br/>
	<br/>
	<br/>
	<br/>
	Warm Regards<br/>
	"
    Email.send_email email_to, subject, body

end


module Email
	def self.send_email_certificate email_to, subject, body , filename

		email_from = 'dev@elevatozloyalty.com'
        if ENV['RACK_ENV'] == 'staging'
            email_from = email_from
			email_to.push 'mahesh@mverve.com'
        elsif ENV['RACK_ENV'] == 'production'
			email_from = email_from
			email_to.push 'nitish.shukla@elevatozloyalty.com'

        end

		if ENV['RACK_ENV'] == 'production' or ENV['RACK_ENV'] == 'staging'
			certificate_root = File.expand_path(File.join(File.dirname(__FILE__),'..','..','public','uploads','certificates'))
			fullfilepath = File.expand_path(File.join(certificate_root, "#{filename}"))


			attachment = Base64.encode64(File.open(fullfilepath, 'rb') {|file| file.read })

			options = {
				attachments: [{
					name: filename,
					type: 'image/png',
					data: attachment
				}]
			}

			sp = SparkPost::Client.new() # pass api key or get api key from ENV
			response = sp.transmission.send_message(
					email_to,
					email_from,
					subject,
					body,
					options)

        elsif ENV['RACK_ENV'] != 'alltest'
            puts "------------------ SENDING EMAIL ---------------------"
            puts "FROM - '#{email_from}'"
            puts "TO - '#{email_to}'"
            puts
            puts body
            puts "------------------------------------------------------"
        end

    rescue Exception => e
        raise e.message
	end

	def self.send_email email_to, subject, body

		email_from = 'dev@elevatozloyalty.com'
        if ENV['RACK_ENV'] == 'staging'
            email_from = email_from
			email_to.push 'mahesh@mverve.com'
        elsif ENV['RACK_ENV'] == 'production'
			email_from = email_from
			email_to.push 'nitish.shukla@elevatozloyalty.com'

        end

		if ENV['RACK_ENV'] == 'production' or ENV['RACK_ENV'] == 'staging'

			sp = SparkPost::Client.new() # pass api key or get api key from ENV
			response = sp.transmission.send_message(
					email_to,
					email_from,
					subject,
					body)

        elsif ENV['RACK_ENV'] != 'alltest'
            puts "------------------ SENDING EMAIL ---------------------"
            puts "FROM - '#{email_from}'"
            puts "TO - '#{email_to}'"
            puts
            puts body
            puts "------------------------------------------------------"
        end

    rescue Exception => e
        raise e.message
    end
end