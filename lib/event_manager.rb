require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('../output') unless Dir.exist?('../output')

  filename = "../output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def generate_thank_you_letter
    puts 'EventManager initialized.'

    contents = CSV.open(
    '../event_attendees.csv',
    headers: true,
    header_converters: :symbol
    )

    template_letter = File.read('../form_letter.erb')
    erb_template = ERB.new template_letter

    contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id,form_letter)
    end
end

def extract_phone_numbers
  clean_phone_numbers = []

  puts 'EventManager initialized.'

  contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )
  
  contents.each do |row|
    phone_number = row[:homephone]

    # learn how to do this in gsub / regular expressions
    phone_number = phone_number.delete(' ')
    phone_number = phone_number.delete('-')
    phone_number = phone_number.delete('(')
    phone_number = phone_number.delete(')')
    phone_number = phone_number.delete('.')
    
    # If the phone number is less than 10 digits, assume that it is a bad number
    # If the phone number is 10 digits, assume that it is good
    # If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
    # If the phone number is 11 digits and the first number is not 1, then it is a bad number
    # If the phone number is more than 11 digits, assume that it is a bad number

    if phone_number.length < 10
      next
    elsif phone_number.length == 10
      clean_phone_numbers.push(phone_number)
    elsif phone_number.length == 11 && phone_number[0] == "1"
      clean_phone_numbers.push(phone_number[1...phone_number.length])
    end
  end

  puts clean_phone_numbers
end

# output: {hour => frequency}
def hour_targeting

  hour_array = []
  puts 'EventManager initialized.'

  contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )
  
  contents.each do |row|
    date_and_time = row[:regdate]
    # date_and_time_array = date_and_time.split(" ")

    # "#{date_and_time_array[0]}  #{date_and_time_array[1]}"
    # 11/12/08  10:47

    #puts Time.parse(date_and_time)
    time_object = Time.strptime(date_and_time, "%m/%d/%y %k:%M")
    hour_array.push(time_object.hour)

  end
  p hour_array.tally.sort_by(&:last).to_h
end

# output: {day of week => frequency}
# 0 = Sunday
def day_of_week_targeting

  day_of_week_array = []
  puts 'EventManager initialized.'

  contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )
  
  contents.each do |row|
    date_and_time = row[:regdate]
    # date_and_time_array = date_and_time.split(" ")

    # "#{date_and_time_array[0]}  #{date_and_time_array[1]}"
    # 11/12/08  10:47

    #puts Time.parse(date_and_time)
    date_object = Date.strptime(date_and_time, "%m/%d/%y %k:%M")
    day_of_week_array.push(date_object.wday)

  end
  p day_of_week_array.tally.sort_by(&:last).to_h
end

day_of_week_targeting