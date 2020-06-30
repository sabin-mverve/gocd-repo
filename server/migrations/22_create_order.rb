Sequel.migration do
	up do
		create_table(:orders) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			String		:order_number,
						:allow_null => false,
						:default => ''

			index		:order_number


			Integer		:points

			Integer		:num_items

			String		:name,
						:allow_null => false,
						:default => ''

			String		:mobile

			String		:email

			String 		:address1,
						:allow_null => false,
						:default => ''

			String 		:address2,
						:default => ''

			String 		:district

			String 		:city,
						:allow_null => false,
						:default => ''

			String 		:state,
						:allow_null => false,
						:default => ''

			String 		:pincode,
						:allow_null => false,
						:default => ''

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

    end

    down do
		drop_table(:orders)
	end

end