Sequel.migration do
    up do
        create_table(:versions) do
            primary_key :id

            String      :platform,
                        :allow_null => false

            String      :vcode,
                        :allow_null => false
        end
    end

    down do
        drop_table(:versions)
    end
end
