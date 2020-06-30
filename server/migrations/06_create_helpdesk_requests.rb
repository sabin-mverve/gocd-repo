Sequel.migration do
	change do
		create_table(:helpdesk_requests) do
			primary_key	:id

			String		:type,
						:allow_null => false,
						:default => nil

			String		:participant_type,
						:allow_null => false,
						:default => nil

			String		:name,
						:allow_null => false,
						:default => nil

			String		:mobile,
						:allow_null => false,
						:default => nil

			index		:mobile

			String		:keyword,
						:default => nil

			String		:received_on,
						:default => nil

			String		:message,
						:default => nil

			String		:referred_by,
						:default => nil

			String		:address1,
						# :allow_null => false,
						:default => nil

			String		:address2,
						:default => nil

			String		:address3,
						:default => nil

			# String		:city,
			# 			:allow_null => false,
			# 			:default => nil

			# String		:state,
			# 			:allow_null => false,
			# 			:default => nil

			foreign_key	:state_id,
						:states,
						:key 		=> :id,
						:on_delete 	=> :restrict,
						:default => nil

			foreign_key	:city_id,
						:cities,
						:key 		=> :id,
						:on_delete 	=> :restrict,
						:default => nil

			String		:pincode,
						# :allow_null => false,
						:default => nil

			String		:store_name,
						# :allow_null => false
						:default => nil

			Date 		:dob,
						:default => nil
			Date 		:doa,
						:default => nil
			Date 		:doj,
						:default => nil
			Integer 		:age,
						:default => nil

			String		:email,
						:default => nil

			String		:district,
						:default => nil

			String    	:mother_tongue,
						:default => nil

			String      :experience,
						:default => nil

			String      :qualification,
						:default => nil

			String		:parent_mobile,
						:default => nil

			Integer		:parent_id,
						:default => nil

			String 		:status,
						:default => 'incomplete',
						:allow_null => false


			DateTime	:created_at
			DateTime	:updated_at
			DateTime	:deleted_at

		end
	end
end

