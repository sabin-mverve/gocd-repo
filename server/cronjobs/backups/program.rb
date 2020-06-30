# * ====================================================
# * This program has to be run via config/schedule.rb
# * ====================================================

sqlite_db_folder = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'database'))

Dir.chdir sqlite_db_folder do
	`ruby backup_from_postgres_to_sqlite.rb`
end