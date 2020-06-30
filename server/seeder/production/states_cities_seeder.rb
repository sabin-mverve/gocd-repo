# require 'json'
require 'yaml/store'

def seed_states_and_cities
	states_cities_yaml_file = File.expand_path(File.join(File.dirname(__FILE__), 'states_and_cities.yaml'))

	yamlstore = YAML.load_file states_cities_yaml_file
	t = Time.now
	DB.transaction do
		yamlstore['states_and_cities'].each do |state|
			state_name = state[:name].strip
			# p state_name
			st = State.where(name: state_name).first

			if !st
				st = State.create(name: state_name)
			end

			if st.cities_dataset.count.zero?
				city_array_hashes = state[:cities].collect do |city|
					city_name = city[:name].strip
					{
						name: city_name,
						state_id: st.id,
						created_at: t,
						updated_at: t
					}
				end

				st.cities_dataset.multi_insert city_array_hashes
			end
		end
	end

	puts 'States and Cities - seeded'
end

# seed_states_and_cities