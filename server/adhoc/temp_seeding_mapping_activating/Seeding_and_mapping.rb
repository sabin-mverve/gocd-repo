require 'dotenv'

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
    require './server/app/models'
end
`cls`
workbook = Roo::Spreadsheet.open "./Upload_SO_details.xlsx"

firstsheet = workbook.sheet(0)


dl_from_sheets = []
ds_from_sheets = []
so_from_sheets = []
asm_from_sheets = []
rm_from_sheets = []


ret =[]
created_record = []
updated_record = 0
skipped = []
user_updated = []


firstsheet.each_with_index(
	sales_head: 'SH Name',
	sales_head_phone: 'SH Mobile',
	regional_manager:'RM Name',
	regional_manager_phone:'RM Mobile',
	asm:'ASM Name',
	asm_phone:'ASM Mobile',
	so_name:'SO Name',
	so_phone:'SO Mobile',


) do |row, ind|
	next if ind < 1

	sh_name = row[:sales_head]
	sh_mobile = row[:sales_head_phone].to_s
	rm_name = row[:regional_manager]
	rm_mobile = row[:regional_manager_phone].to_s
	asm_name = row[:asm]
	asm_mobile = row[:asm_phone].to_s
	so_name = row[:so_name]
	so_mobile = row[:so_phone].to_s


	so_mobile = "91#{so_mobile}" if so_mobile.length == 10
	asm_mobile = "91#{asm_mobile}" if asm_mobile.length == 10
	rm_mobile = "91#{rm_mobile}" if rm_mobile.length == 10
	sh_mobile = "91#{sh_mobile}" if sh_mobile.length == 10

	so_from_sheets.push({
		sh_name:sh_name,
		sh_mobile:sh_mobile,
		rm_name:rm_name,
		rm_mobile:rm_mobile,
		asm_name:asm_name,
		asm_mobile:asm_mobile,
		so_name:so_name,
		so_mobile:so_mobile,
	})

	asm_from_sheets.push({
		sh_name:sh_name,
		sh_mobile:sh_mobile,
		rm_name:rm_name,
		rm_mobile:rm_mobile,
		asm_name:asm_name,
		asm_mobile:asm_mobile,
	})

	rm_from_sheets.push({
		sh_name:sh_name,
		sh_mobile:sh_mobile,
		rm_name:rm_name,
		rm_mobile:rm_mobile,
	})
end

DB.transaction do

		so_from_sheets.each do |rec|
			if !rec[:so_mobile].empty?

				so_exists = Participant.where(mobile: rec[:so_mobile]).first

				if !so_exists
					new_so = Participant.new(
						mobile: rec[:so_mobile],
						active:true,
						name:rec[:so_name],
						role:'p'
					)
					permissions = {
						role_name:'so'
					}

					new_so.permission_attributes = permissions
					new_so.save
					created_record.push rec[:so_mobile]+'so created'

				else
					so_exists.update(
						mobile: rec[:so_mobile],
						name: rec[:so_name]
					)
					updated_record +=1
				end

			end
		end

		asm_from_sheets.each do |rec|

			if !rec[:asm_mobile].empty?

				asm_exists = Participant.where(mobile: rec[:asm_mobile]).first

				if !asm_exists
					new_asm = Participant.new(
						mobile: rec[:asm_mobile],
						active:true,
						name:rec[:asm_name],
						role:'p'
					)
					permissions = {
						role_name:'asm'
					}

					new_asm.permission_attributes = permissions
					new_asm.save
					created_record.push rec[:asm_mobile]+'asm created'
				else
					asm_exists.update(
						mobile: rec[:asm_mobile],
						name: rec[:asm_name]
					)
					updated_record +=1
				end
			end
		end

		rm_from_sheets.each do |rec|
			if !rec[:rm_mobile].empty?
				rm_exists = Participant.where(mobile: rec[:rm_mobile]).first

				if !rm_exists
					new_rm = Participant.new(
						mobile: rec[:rm_mobile],
						name:rec[:rm_name],
						role:'p'
					)
					permissions = {
						role_name:'rm'
					}

					new_rm.permission_attributes = permissions
					new_rm.save
					created_record.push rec[:rm_mobile]+'rm created'
				else
					skipped.push rec[:rm_mobile]

				end
			end

			if !rec[:sh_mobile].empty?
				sh_exists = Participant.where(mobile: rec[:sh_mobile]).first

				if !sh_exists
					new_sh = Participant.new(
						mobile: rec[:sh_mobile],
						name:rec[:sh_name],
						role:'p'
					)
					permissions = {
						role_name:'sh'
					}

					new_sh.permission_attributes = permissions
					new_sh.save
					created_record.push rec[:sh_mobile]+'sh created'
				else
					skipped.push rec[:sh_mobile]

				end
			end

		end


		#! Mapping parent_id

		so_from_sheets.each do |rec|

			so = Participant.where(mobile: rec[:so_mobile]).first
			asm = Participant.where(mobile: rec[:asm_mobile]).first
			rm = Participant.where(mobile: rec[:rm_mobile]).first
			sh = Participant.where(mobile: rec[:sh_mobile]).first


			if so and !so[:parent_id] and asm
				so.update(
					parent_id: asm[:id]
				)
			end

			if asm and !asm[:parent_id] and rm
				asm.update(
					parent_id: rm[:id]
				)
			end

			if rm and !rm[:parent_id] and sh
				rm.update(
					parent_id: sh[:id]
				)
			end


		end

		Permission.where(role_name: ['rm','sh']).collect do |permission|
			if !permission.participant.active
				user = permission.participant
				user.update(
					active:true
				)
				user_updated.push user.mobile
			end
		end

	ret ={
		created:created_record,
		updated: updated_record,
		activated: user_updated
		# skipped: skipped

	}
	# p user_updated

	y ret
	raise Sequel::Rollback
end
