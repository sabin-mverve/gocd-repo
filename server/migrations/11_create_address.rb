Sequel.migration do
	up do
		create_table(:addresses) do

			primary_key	:id

			String      :name

			String      :mobile,
						:allow_null => false

			String      :address1
			String      :address2
			String      :address3

			String      :district

			String      :pincode

			foreign_key	:state_id,
						:states,
						:key 		=> :id,
						:on_delete 	=> :restrict,
						:allow_null => false

			foreign_key	:city_id,
						:cities,
						:key 		=> :id,
						:on_delete 	=> :restrict,
						:allow_null => false

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end


	down do
		drop_table(:addresses)
	end
end