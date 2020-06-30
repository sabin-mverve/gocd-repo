Sequel.migration do
	change do
		create_table(:knowledge_banks) do

			primary_key	:id

			String		:room,
                        :allow_null => false

			String		:weight,
                        :allow_null => false

			String		:material,
                        :allow_null => false

			String		:firmness,
                        :allow_null => false

			String		:priority,
                        :allow_null => false

			String		:budget,
                        :allow_null => false

			String		:old_mattress,
                        :allow_null => false

			String		:thickness,
                        :allow_null => false

			String		:collection,
                        :allow_null => false

			String		:product,
						:allow_null => false

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end
end