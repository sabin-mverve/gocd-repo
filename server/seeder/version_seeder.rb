require "syck"
require_relative "../app/models"

def seed_version
    Version.create({
        platform: 'ios',
        vcode: '1.0.0'
    })

    Version.create({
        platform: 'android',
        vcode: '1.0.0'
    })

    puts 'Seeded version'
end
