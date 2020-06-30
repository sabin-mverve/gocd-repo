Sequel.migration do
	change do
		create_table(:levels_questions) do

			primary_key		:id

			foreign_key		:level_title_id,
							:levels,
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