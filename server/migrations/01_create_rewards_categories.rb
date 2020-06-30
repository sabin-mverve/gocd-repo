Sequel.migration do
	up do
		create_table(:reward_categories) do

			primary_key	:id

			String		:name
			String		:image

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end


	down do
		drop_table(:reward_categories)
	end

end