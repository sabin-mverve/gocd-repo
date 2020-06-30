Sequel.migration do
    change do
        create_table(:feedback) do

            primary_key	:id

            foreign_key	:user_id,
                        :users,
                        :key 		=> :id,
                        :on_delete 	=> :cascade,
                        :allow_null => false

            String      :customer_mobile,
                        :allow_null => false

            String		:content,
                        :default => nil

            DateTime	:received_on

            DateTime	:created_at
            DateTime	:updated_at
            DateTime	:deleted_at

        end

    end

end