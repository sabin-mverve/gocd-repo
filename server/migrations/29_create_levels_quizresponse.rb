Sequel.migration do
	change do
		create_table(:levels_quizresponse) do

			primary_key			:id

			foreign_key			:level_title_id,
								:levels,
								:key	=> :id,
								:on_delete	=> :cascade

			String				:response

			Integer				:user_id


			boolean				:completed,
								:default => false

			boolean				:pending,
								:default => false

			boolean				:attempted,
								:default => false


			DateTime			:created_at
			DateTime			:updated_at
			DateTime			:deleted_at
		end
	end
end