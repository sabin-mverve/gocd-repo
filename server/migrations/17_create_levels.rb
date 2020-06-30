Sequel.migration do
	change do
		create_table(:levels) do

			primary_key		:id

			Integer			:level,
							:allow_null => false

			Integer			:points,
							:allow_null => false

			String			:title,
							:allow_null => false

			String			:description,
							:allow_null => false


			TrueClass		:published,
							:allow_null => false,
							:default => false

			DateTime		:published_date

			DateTime		:unpublished_date


			DateTime		:created_at
			DateTime		:updated_at
			DateTime		:deleted_at


		end
	end
end