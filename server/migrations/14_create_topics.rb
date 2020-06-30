Sequel.migration do
	change do
		create_table(:topics) do

			primary_key		:id

			Integer			:month,
							:allow_null => false

			Integer			:year,
							:allow_null => false

			# String			:topic_date,
			# 				:allow_null => false

			String			:topic,
							:allow_null => false

			String			:description

			TrueClass		:published,
							:default => false

			TrueClass		:attempted,
							:default => false


			Integer			:video_id


			DateTime		:created_at
			DateTime		:updated_at
			DateTime		:deleted_at


		end
	end
end