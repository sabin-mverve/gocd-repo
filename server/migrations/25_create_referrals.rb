Sequel.migration do
	change do
		create_table(:referrals) do

			primary_key	:id

			foreign_key :referred_by_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :restrict

			foreign_key :referred_to_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :restrict

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end
end