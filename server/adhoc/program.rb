require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
    require './server/app/models'
end

workbook = Roo::Spreadsheet.open "./New Hierarchy(LnD).xlsx"

firstsheet = workbook.sheet(0)

cso_from_sheets = []


ret =[]
created_record = []
updated_record = 0
exists = []

firstsheet.each_with_index(

		program_head_name: 'Program Head  Name',
		program_head_mobile: 'Program Head Mobile',
		cso_name:'Company Sales Officer Name',
		cso_mobile:'Company Sales Officers Mobile',


	) do |row, ind|
		next if ind < 1

		ph_name = row[:program_head_name]
		ph_mobile = row[:program_head_mobile].to_s
		cso_name = row[:cso_name]
		cso_mobile = row[:cso_mobile].to_s


		cso_mobile = "91#{cso_mobile}" if cso_mobile.length == 10
		ph_mobile = "91#{ph_mobile}" if ph_mobile.length == 10



		cso_from_sheets.push({
			ph_name:ph_name,
			ph_mobile:ph_mobile,
			cso_name:cso_name,
			cso_mobile:cso_mobile,
		})
end

DB.transaction do

		cso_from_sheets.each do |rec|
			if !rec[:cso_mobile].empty?
				cso_exists = Participant.where(mobile: rec[:cso_mobile]).first

				if !cso_exists
					new_cso = Participant.new(
						mobile: rec[:cso_mobile],
						name:rec[:cso_name],
						role:'p'
					)
					permissions = {
						role_name:'cso'
					}

					new_cso.permission_attributes = permissions
					new_cso.save
					created_record.push rec[:cso_mobile]+'cso created'
				else
					exists.push rec[:cso_mobile]

				end
			end

			if !rec[:ph_mobile].empty?
				ph_exists = Participant.where(mobile: rec[:ph_mobile]).first

				if !ph_exists
					new_ph = Participant.new(
						mobile: rec[:ph_mobile],
						name:rec[:ph_name],
						role:'p'
					)
					permissions = {
						role_name:'ph'
					}

					new_ph.permission_attributes = permissions
					new_ph.save
					created_record.push rec[:ph_mobile]+'ph created'
				else
					exists.push rec[:ph_mobile]

				end
			end

		end


		#! Mapping parent_id

		cso_from_sheets.each do |rec|

			cso = Participant.where(mobile: rec[:cso_mobile]).first
			ph = Participant.where(mobile: rec[:ph_mobile]).first


			if cso and !cso[:parent_id] and ph
				cso.update(
					parent_id: ph[:id]
				)
			end


		end

	ret ={
		created:created_record,
		updated: updated_record,
		exists: exists

	}

	y ret
	raise Sequel::Rollback
end
