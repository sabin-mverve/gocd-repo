
def seed_products
    DB.transaction do
        workbook = Roo::Spreadsheet.open 'server/seeder/production/product_master.xlsx'
        product_master = workbook.sheet(0)

        product_master.each_with_index(
            material: 'Material',
            description: 'Material description',
            group: 'Material Group',
            measure: 'Base Unit of Measure',
            points: 'Points'
        ) do |row, ind|
            next if ind < 1

            points = row[:points]

            if points.to_s.empty?
                p "Points not present - rejected"
                next
            end

            Product.create(
                material: row[:material],
                description: row[:description],
                group: row[:group],
                measure: row[:measure],
                points: points
            )

        end
        # raise Sequel::Rollback
    end
    puts 'Product Master - seeded'
end