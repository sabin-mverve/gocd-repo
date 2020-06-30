require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

given_dealer = "918686287543"
given_so = "919949856979"
older_one = "919440182456"
alter_number = "919440182465"

DB.transaction do
	dealer = Participant.where(mobile: given_dealer).first
	so = Participant.where(mobile: given_so).first

	dealer.permission.update(
		role_name: 'rsa'
	)
	dealer.update(
		parent_id: so.id
    )
    
    number_change = Participant.where(mobile: older_one).first
    number_change.update(
        mobile: alter_number
    )

	p dealer.permission.role_name
    p dealer
    
    p number_change
	# raise Sequel::Rollback

end
