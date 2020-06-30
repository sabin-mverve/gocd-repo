Sequel.migration do
	change do
		create_table(:permissions) do

			primary_key	:id

			String		:role_name,
						:allow_null => false

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			TrueClass	:claim,
                        :default => false

			TrueClass	:pointsearn,
						:default => false

			TrueClass	:cart,
						:default => false

			TrueClass	:redemption,
						:default => false

			TrueClass	:refer,
						:default => false

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end
end