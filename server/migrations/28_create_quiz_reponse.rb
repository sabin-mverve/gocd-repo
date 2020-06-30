Sequel.migration do
	change do
		create_table(:quiz_response) do

			primary_key			:id

			foreign_key			:topic_id,
								:topics,
								:key	=> :id,
								:on_delete	=> :cascade

			String				:response

			foreign_key		    :user_id,
								:users,
								:key 		=> :id,
								:on_delete 	=> :cascade,
								:allow_null => false


			boolean				:completed,
								:default => false

			boolean				:pending,
								:default => false

			DateTime			:created_at
			DateTime			:updated_at
			DateTime			:deleted_at
		end
	end
end