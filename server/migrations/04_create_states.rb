Sequel.migration do
	up do
		create_table(:states) do

			primary_key	:id

			String		:name,
						allow_null: false

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end

	down do
		drop_table(:states)
	end
end