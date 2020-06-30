Sequel.migration do
	change do
		create_table(:materials) do

			primary_key	:id

			foreign_key		:level_title_id,
							:levels,
							:key 		=> :id,
							:on_delete 	=> :cascade

			String			:material

			String			:material_type

			integer			:material_number

			DateTime		:created_at
			DateTime		:updated_at
			DateTime		:deleted_at

		end
	end
end