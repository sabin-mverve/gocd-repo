Sequel.migration do
	up do
		create_table(:participant_details) do

			primary_key	:id

			Date		:dob,
						:default => nil

			Date		:doa,
                        :default => nil

			Date		:doj,
                        :default => nil

			String 		:store_name

            String		:experience

			String		:qualification

			String		:mother_tongue

			foreign_key :user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end

	down do
		drop_table(:participant_details)
	end
end