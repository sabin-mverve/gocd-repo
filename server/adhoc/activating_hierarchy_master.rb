require 'dotenv'
require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir app_root do
	Dotenv.load
	Dotenv.load ".env.#{ENV['RACK_ENV']}"
    require './server/app/models'
end

workbook = Roo::Spreadsheet.open "./New Hierarchy(LnD).xlsx"

firstsheet = workbook.sheet(0)

cso_from_sheets = []


ret =[]
updated_record = []

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

                if cso_exists
                    if !cso_exists.active 
                        cso_exists.update(
                            active: true
                        ) 
                        updated_record.push rec[:cso_mobile]+' cso status updated'
                    end
				end
            end
            if !rec[:ph_mobile].empty?
				ph_exists = Participant.where(mobile: rec[:ph_mobile]).first

				if ph_exists
					if !ph_exists.active
						
						ph_exists.update(
							active: true
						)
						updated_record.push rec[:ph_mobile]+' ph status updated'
					end
				end
			end
        end

    ret ={
		updated: updated_record
	}

	y ret
	raise Sequel::Rollback
end


