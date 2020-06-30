Sequel.migration do
	up do
		create_table(:orderitems) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			foreign_key	:order_id,
						:orders,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			String		:suborder_number,
						:allow_null => false,
						:default => ''

			String		:status,
						:allow_null => false,
						:default => ''

			String 		:category_name,
						:allow_null => false,
						:default => ''

			String 		:sub_category_name,
						:default => ''

			Integer		:quantity

			String		:name

			String		:model_number

			String		:code

			String		:brand
			String		:description
			String		:image
			String		:thumbnail
			Integer		:points

            Date      	:dispatch_date
            String      :dispatch_awb_num
            String      :dispatch_courier
            Date      	:delivery_date
            String      :remarks



			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

    end

    down do
		drop_table(:orderitems)
	end

end