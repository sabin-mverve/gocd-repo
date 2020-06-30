Sequel.migration do
	up do
		create_table(:cities) do

			primary_key	:id

			String		:name,
						allow_null: false

			index		:name

			foreign_key :state_id,
						:states,
						:key 		=> :id,
						:on_delete 	=> :restrict

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end


	down do
		drop_table(:cities)
	end

end