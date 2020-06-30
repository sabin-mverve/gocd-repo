Sequel.migration do
	change do
		create_table(:certificates) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false


			Integer 	:level_title_id
			# foreign_key	:level_title_id,
			# 			:levels,
			# 			:key 		=> :id,
			# 			:on_delete 	=> :cascade

			String      :certificate
			Integer		:level


			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end

end