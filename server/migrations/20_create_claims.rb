Sequel.migration do
	up do
		create_table(:claims) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			String		:type,
						:allow_null => false,
						:default => nil

			String		:code,
						:allow_null => false,
						:default => nil

			Integer		:total_points,
						:default => 0

			Integer		:points_debited,
						:default => 0

			String		:description

			String		:category

			foreign_key :coupon_id,
						:coupons,
						:key 		=> :id,
						:on_delete 	=> :restrict

			foreign_key :topic_id,
						:topics,
						:key 		=> :id,
						:on_delete 	=> :restrict

			foreign_key :level_title_id,
						:levels,
						:key 		=> :id,
						:on_delete 	=> :restrict

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end


	down do
		drop_table(:claims)
	end

end