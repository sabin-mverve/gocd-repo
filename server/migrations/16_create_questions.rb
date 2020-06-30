Sequel.migration do
	change do
		create_table(:questions) do

			primary_key		:id

			foreign_key		:topic_id,
							:topics,
							:key	=> :id,
							:on_delete	=> :cascade

			String			:question

			String			:options
			Integer			:correct

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at
		end
	end
end