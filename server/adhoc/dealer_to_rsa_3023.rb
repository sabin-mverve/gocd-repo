require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end
given_dealer_to_rsa = '918074926189'
mapping_dealer = '919949628428'

DB.transaction do
    
    participant_update = Participant.where(mobile: given_dealer_to_rsa).first
    if participant_update
        mapping_dealer_detail = Participant.where(mobile: mapping_dealer).first
        if mapping_dealer_detail
            participant_update.update(
                parent_id: mapping_dealer_detail.id
            )
        end
        participant_update.permission.update(
            claim: true,
            pointsearn: true,
            cart: true,
            redemption: true,
            refer: false,
            role_name: 'rsa'
        )
    end

    p participant_update.permission
	# raise Sequel::Rollback

end
