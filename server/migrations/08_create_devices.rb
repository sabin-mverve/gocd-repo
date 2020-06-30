Sequel.migration do
	change do
		create_table(:devices) do

			primary_key	:id

			foreign_key :user_id,
						:users,
						:key 		=> :id,
						:on_delete 	=> :cascade

			String		:password_digest,
						:default => nil
			String		:password_text,
						:default => nil

			String		:otp,
						:default => nil

			DateTime	:otp_expires,
						:default => nil

			String		:token,
						:default => nil

			String		:player_id,
						:default => nil

			String		:reset,
						:default => nil

			DateTime	:reset_expires,
						:default => nil

			String		:user_agent,
						:default => nil

			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end

	end

end