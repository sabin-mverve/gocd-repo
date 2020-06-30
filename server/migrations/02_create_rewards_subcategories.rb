Sequel.migration do
	change do
		create_table(:reward_sub_categories) do

			primary_key	:id

			String		:name

            foreign_key	:category_id,
                        :reward_categories,
                        :key 		=> :id,
                        :on_delete 	=> :cascade,
                        :allow_null => false

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end

end