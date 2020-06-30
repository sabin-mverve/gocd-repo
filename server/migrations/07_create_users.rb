Sequel.migration do
	up do
		create_table(:users) do
			primary_key	:id

			foreign_key :parent_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :restrict

			String		:mobile,
						:default => nil

			String		:email,
						:default => nil

			index		:mobile

			String		:name,
						:default => nil

			index		:name

			TrueClass	:active,
						:default => false

			String		:role,
						:allow_null => false


			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end


	down do
		self[:users].
		order(:parent_id).
		reverse.
		update( :parent_id => nil )

		drop_table(:users)
	end

end