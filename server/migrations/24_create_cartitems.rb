Sequel.migration do
	up do
		create_table(:cartitems) do

			primary_key	:id

			Integer		:quantity,
						:default => 1,
						:allow_null => false

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			foreign_key	:reward_id,
						:rewards,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

    end

    down do
		drop_table(:cartitems)
	end
end