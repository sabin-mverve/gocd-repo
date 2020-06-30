app_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
# require 'pp'

begin
Dir.chdir app_root do
	require 'bundler'
	Bundler.require(:default, ENV['RACK_ENV'].to_sym)

	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"

	file_name =  "centuary.prod.sqlite"
	sqlitedb_file = "./database/#{file_name}"

	Sequel.extension :migration

	SQLITEDB = Sequel.connect( :adapter => 'sqlite', :database => sqlitedb_file)
	PGDB_MIGRATE = Sequel.connect adapter: 'postgres', host: 'localhost', port: 5432, database: ENV['PG_DB'], user: ENV['PG_USERNAME'], password: ENV['PG_PASSWORD']

	PGDB_MIGRATE.transaction do
		Sequel::Migrator.run(PGDB_MIGRATE, "server/migrations", target: 0)
		Sequel::Migrator.run(PGDB_MIGRATE, "server/migrations")
	end

	PG_DB = Sequel.connect adapter: 'postgres', host: 'localhost', port: 5432, database: ENV['PG_DB'], user: ENV['PG_USERNAME'], password: ENV['PG_PASSWORD']

	PG_DB.transaction do
		PG_DB[:reward_categories].multi_insert SQLITEDB[:reward_categories].all
		PG_DB[:reward_sub_categories].multi_insert SQLITEDB[:reward_sub_categories].all
		PG_DB[:rewards].multi_insert SQLITEDB[:rewards].all
		PG_DB[:states].multi_insert SQLITEDB[:states].all
		PG_DB[:cities].multi_insert SQLITEDB[:cities].all
		PG_DB[:helpdesk_requests].multi_insert SQLITEDB[:helpdesk_requests].all
		PG_DB[:users].multi_insert SQLITEDB[:users].all
		PG_DB[:devices].multi_insert SQLITEDB[:devices].all
		PG_DB[:participant_details].multi_insert SQLITEDB[:participant_details].all
		PG_DB[:permissions].multi_insert SQLITEDB[:permissions].all
		PG_DB[:addresses].multi_insert SQLITEDB[:addresses].all
		PG_DB[:products].multi_insert SQLITEDB[:products].all
		PG_DB[:coupons].multi_insert SQLITEDB[:coupons].all
		PG_DB[:topics].multi_insert SQLITEDB[:topics].all
		PG_DB[:questions].multi_insert SQLITEDB[:questions].all
		PG_DB[:attachments].multi_insert SQLITEDB[:attachments].all
		PG_DB[:levels].multi_insert SQLITEDB[:levels].all
		PG_DB[:materials].multi_insert SQLITEDB[:materials].all
		PG_DB[:levels_questions].multi_insert SQLITEDB[:levels_questions].all
		PG_DB[:points].multi_insert SQLITEDB[:points].all
		PG_DB[:claims].multi_insert SQLITEDB[:claims].all
		PG_DB[:orders].multi_insert SQLITEDB[:orders].all
		PG_DB[:orderitems].multi_insert SQLITEDB[:orderitems].all
		PG_DB[:cartitems].multi_insert SQLITEDB[:cartitems].all
		PG_DB[:versions].multi_insert SQLITEDB[:versions].all
		PG_DB[:quiz_response].multi_insert SQLITEDB[:quiz_response].all
		PG_DB[:knowledge_banks].multi_insert SQLITEDB[:knowledge_banks].all
		PG_DB[:referrals].multi_insert SQLITEDB[:referrals].all
		PG_DB[:material_counter].multi_insert SQLITEDB[:material_counter].all
		PG_DB[:levels_quizresponse].multi_insert SQLITEDB[:levels_quizresponse].all
		PG_DB[:certificates].multi_insert SQLITEDB[:certificates].all
		PG_DB[:report_download_requests].multi_insert SQLITEDB[:report_download_requests].all

		PG_DB.run "SELECT setval('reward_categories_id_seq', (SELECT MAX(id) FROM reward_categories)+1)"
		PG_DB.run "SELECT setval('reward_sub_categories_id_seq', (SELECT MAX(id) FROM reward_sub_categories)+1)"
		PG_DB.run "SELECT setval('rewards_id_seq', (SELECT MAX(id) FROM rewards)+1)"
		PG_DB.run "SELECT setval('states_id_seq', (SELECT MAX(id) FROM states)+1)"
		PG_DB.run "SELECT setval('cities_id_seq', (SELECT MAX(id) FROM cities)+1)"
		PG_DB.run "SELECT setval('helpdesk_requests_id_seq', (SELECT MAX(id) FROM helpdesk_requests)+1)"
		PG_DB.run "SELECT setval('users_id_seq', (SELECT MAX(id) FROM users)+1)"
		PG_DB.run "SELECT setval('devices_id_seq', (SELECT MAX(id) FROM devices)+1)"
		PG_DB.run "SELECT setval('participant_details_id_seq', (SELECT MAX(id) FROM participant_details)+1)"
		PG_DB.run "SELECT setval('permissions_id_seq', (SELECT MAX(id) FROM permissions)+1)"
		PG_DB.run "SELECT setval('addresses_id_seq', (SELECT MAX(id) FROM addresses)+1)"
		PG_DB.run "SELECT setval('products_id_seq', (SELECT MAX(id) FROM products)+1)"
		PG_DB.run "SELECT setval('coupons_id_seq', (SELECT MAX(id) FROM coupons)+1)"
		PG_DB.run "SELECT setval('topics_id_seq', (SELECT MAX(id) FROM topics)+1)"
		PG_DB.run "SELECT setval('questions_id_seq', (SELECT MAX(id) FROM questions)+1)"
		PG_DB.run "SELECT setval('attachments_id_seq', (SELECT MAX(id) FROM attachments)+1)"
		PG_DB.run "SELECT setval('levels_id_seq', (SELECT MAX(id) FROM levels)+1)"
		PG_DB.run "SELECT setval('materials_id_seq', (SELECT MAX(id) FROM materials)+1)"
		PG_DB.run "SELECT setval('levels_questions_id_seq', (SELECT MAX(id) FROM levels_questions)+1)"
		PG_DB.run "SELECT setval('points_id_seq', (SELECT MAX(id) FROM points)+1)"
		PG_DB.run "SELECT setval('claims_id_seq', (SELECT MAX(id) FROM claims)+1)"
		PG_DB.run "SELECT setval('orders_id_seq', (SELECT MAX(id) FROM orders)+1)"
		PG_DB.run "SELECT setval('orderitems_id_seq', (SELECT MAX(id) FROM orderitems)+1)"
		PG_DB.run "SELECT setval('cartitems_id_seq', (SELECT MAX(id) FROM cartitems)+1)"
		PG_DB.run "SELECT setval('versions_id_seq', (SELECT MAX(id) FROM versions)+1)"
		PG_DB.run "SELECT setval('quiz_response_id_seq', (SELECT MAX(id) FROM quiz_response)+1)"
		PG_DB.run "SELECT setval('knowledge_banks_id_seq', (SELECT MAX(id) FROM knowledge_banks)+1)"
		PG_DB.run "SELECT setval('referrals_id_seq', (SELECT MAX(id) FROM referrals)+1)"
		PG_DB.run "SELECT setval('material_counter_id_seq', (SELECT MAX(id) FROM material_counter)+1)"
		PG_DB.run "SELECT setval('levels_quizresponse_id_seq', (SELECT MAX(id) FROM levels_quizresponse)+1)"
		PG_DB.run "SELECT setval('certificates_id_seq', (SELECT MAX(id) FROM certificates)+1)"
		PG_DB.run "SELECT setval('report_download_requests_id_seq', (SELECT MAX(id) FROM report_download_requests)+1)"

		# raise Sequel::Rollback
	end
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