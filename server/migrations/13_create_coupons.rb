Sequel.migration do
	change do
		create_table(:coupons) do

			primary_key	:id

			String		:material,
						:allow_null => false

			index		:material

            String		:serial_no

            # Integer		:points

            TrueClass	:redeemed,
						:default => false

			foreign_key :product_id,
						:products,
						:key 		=> :id,
						:on_delete 	=> :restrict

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end
end