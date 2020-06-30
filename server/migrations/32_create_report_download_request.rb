Sequel.migration do
	change do
		create_table(:report_download_requests) do

			primary_key	:id

			foreign_key	:user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade,
						:allow_null => false

			String		:type,
						:default => nil

			String		:status

			String		:download_url

			String		:filename


			Integer     :total_records

			DateTime	:requested_time

			DateTime	:responded_time


			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end

end