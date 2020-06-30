Sequel.migration do
	change do
		create_table(:attachments) do

			primary_key		:id

			foreign_key		:topic_id,
							:topics,
							:key	=> :id,
							:on_delete	=> :cascade

			String			:name
			String			:type

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at
		end
	end
end