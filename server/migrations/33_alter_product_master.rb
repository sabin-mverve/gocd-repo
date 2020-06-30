Sequel.migration do
	up do
		alter_table :products do
			add_column      :collection, String
		end
	end

	down do
		alter_table :products do
			drop_column      :collection
		end
	end
end