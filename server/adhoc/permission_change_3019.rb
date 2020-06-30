require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

DB.transaction do
    
    participant_update = Participant.where(id: 303).first
    if participant_update
        participant_update.permission.update(
            claim: true,
            pointsearn: true,
            cart: true,
            redemption: true,
            refer: false
        )
    end

    p participant_update.permission
	# raise Sequel::Rollback

end
