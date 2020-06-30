require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

given_ph = "919963933548"
new_cso = "919338696412"

DB.transaction do
	cso = Participant.where(mobile: new_cso).first
	ph = Participant.where(mobile: given_ph).first
	if ph
		if !cso
			new_cso = Participant.new(
				mobile: new_cso,
				active: true,
				name: 'Shishirkanta Swain',
				role: 'p',
				parent_id: ph.id
			)
			permissions = {
				role_name:'cso'
			}
		
			new_cso.permission_attributes = permissions
			new_cso.save		
		
			p new_cso.permission.role_name
			p new_cso
		end
	end
	# raise Sequel::Rollback

end
