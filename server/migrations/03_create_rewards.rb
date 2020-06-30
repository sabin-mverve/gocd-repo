Sequel.migration do
	up do
		create_table(:rewards) do

			primary_key	:id

			String		:name

			String		:model_number

			String		:code,
						:allow_null => false

			index		:code

			String		:brand
			String		:description
			String		:image
			String		:thumbnail
			Integer		:points

			TrueClass	:active,
						:default => false

			foreign_key	:category_id,
						:reward_categories,
						:key 		=> :id,
						:on_delete 	=> :restrict,
						:allow_null => false

			foreign_key	:sub_category_id,
						:reward_sub_categories,
						:key 		=> :id,
						:on_delete 	=> :restrict

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end

	down do
		drop_table(:rewards)
	end

end