app_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
db_archive_root = File.expand_path(File.join(app_root, 'backup_database_archive', 'backups'))
# require 'pp'

begin
Dir.chdir app_root do
	require 'bundler'
	Bundler.require(:default, ENV['RACK_ENV'].to_sym)

	%w( date fileutils ).each { |lib| require lib }

	FileUtils.mkdir_p db_archive_root

	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"

	t = Time.now.utc

	tz = TZInfo::Timezone.get 'Asia/Kolkata'
	tutc = tz.period_for_utc t
	ist = t + tutc.utc_offset
	ist_str = ist.strftime("%Y-%m-%d")
	ist_str_for_zip = ist.strftime("%Y-%m-%d")

	file_name =  "centuary.#{ist_str}.sqlite"
	sqlitedb_file = "./database/#{file_name}"

	FileUtils.rm sqlitedb_file if File.exist? sqlitedb_file

	Sequel.extension :migration

	SQLITEDB_MIGRATE = Sequel.connect( :adapter => 'sqlite', :database => sqlitedb_file)
	PGDB = Sequel.connect adapter: 'postgres', host: 'localhost', port: 5432, database: ENV['PG_DB'], user: ENV['PG_USERNAME'], password: ENV['PG_PASSWORD']

	SQLITEDB_MIGRATE.transaction do
		Sequel::Migrator.run(SQLITEDB_MIGRATE, "server/migrations", target: 0)
		Sequel::Migrator.run(SQLITEDB_MIGRATE, "server/migrations")
	end

	SQLITEDB  = Sequel.connect( :adapter => 'sqlite', :database => sqlitedb_file, :connect_sqls=>["PRAGMA foreign_keys = 0"])

	SQLITEDB.transaction do
		SQLITEDB[:reward_categories].multi_insert PGDB[:reward_categories].all
		SQLITEDB[:reward_sub_categories].multi_insert PGDB[:reward_sub_categories].all
		SQLITEDB[:rewards].multi_insert PGDB[:rewards].all
		SQLITEDB[:states].multi_insert PGDB[:states].all
		SQLITEDB[:cities].multi_insert PGDB[:cities].all
		SQLITEDB[:helpdesk_requests].multi_insert PGDB[:helpdesk_requests].all
		SQLITEDB[:users].multi_insert PGDB[:users].all
		SQLITEDB[:devices].multi_insert PGDB[:devices].all
		SQLITEDB[:participant_details].multi_insert PGDB[:participant_details].all
		SQLITEDB[:permissions].multi_insert PGDB[:permissions].all
		SQLITEDB[:addresses].multi_insert PGDB[:addresses].all
		SQLITEDB[:coupons].multi_insert PGDB[:coupons].all
		SQLITEDB[:products].multi_insert PGDB[:products].all
		SQLITEDB[:questions].multi_insert PGDB[:questions].all
		SQLITEDB[:topics].multi_insert PGDB[:topics].all
		SQLITEDB[:attachments].multi_insert PGDB[:attachments].all
		SQLITEDB[:levels].multi_insert PGDB[:levels].all
		SQLITEDB[:materials].multi_insert PGDB[:materials].all
		SQLITEDB[:levels_questions].multi_insert PGDB[:levels_questions].all
		SQLITEDB[:points].multi_insert PGDB[:points].all
		SQLITEDB[:claims].multi_insert PGDB[:claims].all
		SQLITEDB[:orders].multi_insert PGDB[:orders].all
		SQLITEDB[:orderitems].multi_insert PGDB[:orderitems].all
		SQLITEDB[:cartitems].multi_insert PGDB[:cartitems].all
		SQLITEDB[:versions].multi_insert PGDB[:versions].all
		SQLITEDB[:quiz_response].multi_insert PGDB[:quiz_response].all
		SQLITEDB[:knowledge_banks].multi_insert PGDB[:knowledge_banks].all
		SQLITEDB[:referrals].multi_insert PGDB[:referrals].all
		SQLITEDB[:material_counter].multi_insert PGDB[:material_counter].all
		SQLITEDB[:levels_quizresponse].multi_insert PGDB[:levels_quizresponse].all
		SQLITEDB[:certificates].multi_insert PGDB[:certificates].all
		SQLITEDB[:report_download_requests].multi_insert PGDB[:report_download_requests].all

		# raise Sequel::Rollback
	end

	db_archive_file = File.expand_path(File.join(sqlitedb_file))
	db_archive_zip_file = File.expand_path(File.join(db_archive_root, "#{file_name}.zip"))

	`zip #{db_archive_zip_file} #{db_archive_file}`
	# FileUtils.mv db_archive_zip_file, db_archive_root, :force => true
	# FileUtils.rm db_archive_file
end
rescue Exception => e
	message = "\n\n-- ERROR -- \n\n"
	message += e.message
	e.backtrace.each_with_index do |x, i|
		break if (i > 50)
		if x.include?(__FILE__)
			message += "\n#{x}"
		end
	end
	message += "\n"

	puts message
end