
def seed_mattress
    DB.transaction do

        excel = [
            'server/seeder/production/Parents.xlsx',
            'server/seeder/production/Master.xlsx',
            'server/seeder/production/Guest.xlsx',
            'server/seeder/production/Kids.xlsx',
        ]

        excel.each do |e|

           workbook = Roo::Spreadsheet.open e

            # Iterate through each sheet
            workbook.each_with_pagename do |name, sheet|
                # p sheet.row(1)
                sheet.each_with_index(
                    sl_no: 'S.No',
                    room: 'BedRoom',
                    weight: 'Weight',
                    material: 'Material',
                    firmness: 'Firmness',
                    priority: 'Priority',
                    budget: 'Budget',
                    old_mattress: 'Old Mattress',
                    thickness: 'Thickness',
                    collection: 'Collection',
                    product: 'Product'
                ) do |row, ind|
                    next if ind < 1

                    Knowledge_bank.create(
                        room: row[:room],
                        weight: row[:weight],
                        material: row[:material],
                        firmness: row[:firmness],
                        priority: row[:priority],
                        budget: row[:budget],
                        old_mattress: row[:old_mattress],
                        thickness: row[:thickness],
                        collection: row[:collection],
                        product: row[:product]
                    )

                end
            end
        end
        # raise Sequel::Rollback
    end
    puts 'Mattress - seeded'
end