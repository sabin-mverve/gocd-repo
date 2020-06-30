Sequel.migration do
	up do
		create_table(:points) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			Integer		:earned,
						:default => 0,
						:allow_null => false

			Integer		:redeemed,
						:default => 0,
						:allow_null => false


			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end


	down do
		drop_table(:points)
	end

end