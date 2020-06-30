Sequel.migration do
	change do
		create_table(:material_counter) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			foreign_key	:material_id,
						:materials,
						:key 		=> :id,
						:on_delete 	=> :cascade

			TrueClass	:active,
						:default => false

			Float		:resume_counter



			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end

end