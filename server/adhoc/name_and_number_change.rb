require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

older_one = "918919446619"
alter_number = "919533880202"

DB.transaction do

    number_change = Participant.where(mobile: older_one).first
    number_change.update(
        mobile: alter_number,
        name:'G.M.V.S.N.Murthy'
    )
    
    p number_change
	# raise Sequel::Rollback

end
