require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end
given_cso = [{
    name: 'Junaid BE',
    mobile: '919995012478'
},{
    name: 'Vimesh KV',
    mobile: '919847755894'
}]
    
mapping_ph_mobile = '919963933548'

DB.transaction do
    given_cso.each do |cso|
        cso_exists = Participant.where(mobile: cso[:mobile]).first
        if !cso_exists
            mapping_ph = Participant.where(mobile: mapping_ph_mobile).first
            if mapping_ph
                new_cso = Participant.new(
                    mobile: cso[:mobile],
                    active: true,
                    name: cso[:name],
                    role: 'p',
                    parent_id: mapping_ph.id
                )
                permissions = {
                    role_name:'cso'
                }
            
                new_cso.permission_attributes = permissions
                new_cso.save
                p new_cso.permission
            end
        end

    end
    # raise Sequel::Rollback
end
