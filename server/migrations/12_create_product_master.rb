Sequel.migration do
	change do
		create_table(:products) do

			primary_key	:id

			String		:material,
						:allow_null => false

			index		:material

			String		:description
			String		:group
			String		:measure
			Integer		:points

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end
end