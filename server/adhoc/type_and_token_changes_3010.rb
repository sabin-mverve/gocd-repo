require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

updated_record = 0

DB.transaction do
    dealer_permission = Permission.where(role_name: 'dl')
    
	dealer_permission.collect do |dealer|
        # p dealer
        device = Device.where(user_id: dealer.user_id)
        device.update(
            token: nil
        )
        updated_record+=1
    end
    dealer_permission.update(
        refer: false
    )
    
    
    p updated_record 
    p 'dealer permission were updated'
	# raise Sequel::Rollback

end
