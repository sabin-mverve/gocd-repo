require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
	p "--------------env---------------------------"
	p ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

cities = ["Nalgonda", "Miryalguda"]

DB.transaction do
    cities.each do |city|
        city_detail = City.where(name: city).first
        if city_detail
            telangana_state = State.where(name: 'Telangana').first
            if telangana_state
                city_detail.update(
                    state_id: telangana_state.id
                )
                p city_detail
            end
        end
    end
	# raise Sequel::Rollback
end
