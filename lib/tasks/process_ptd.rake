def process_ptds
    filenames = Dir[Rails.root.join('data', 'raw_html', '*', 'leases', 'ptd', '*.html')]

    # filenames = [ '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/ptd/ptd_02286.html', 
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/ptd/ptd_002258.html', 
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/ptd/ptd_09908.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/ptd/ptd_000229.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/ptd/ptd_02909.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/ptd/ptd_004536.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/LIVE OAK/leases/ptd/ptd_001516.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/LIVE OAK/leases/ptd/ptd_001519.html', 
    #               ]

    CSV.open(Rails.root.join('data', 'processed', 'ptd_operators.csv'), 'ab') do |csv|
        filenames.each do |file|
            puts "On file: #{file}"

            lease_no = file.match(/(?<=\_)(\d*?)(?=\.)/).to_s

            html = Nokogiri::HTML(File.open(file, 'r'))

            deets_trs = html.css('table[class="TabBox2"] tbody tr')
            deets_td = deets_trs[1].css('td')
            raw_deets = deets_td.text.gsub(/\n|\s|\u00a0/,'')
            lease_name = raw_deets.match(/(?<=LeaseName:).+(?=,LeaseNo.:)/).to_s.gsub(/"|'|\//,'').strip
            well_type = raw_deets.match(/(?<=WellType:).+(?=CountyName:)/).to_s.strip
            well_no = raw_deets.match(/(?<=WellNo.:).+(?=WellType:)/).to_s.strip

            trs = html.css('table[class="DataGrid"] tbody tr')

            operator_name = trs[4].css('td')[5].text.to_s.strip
            operator_num = trs[4].css('td')[6].text.to_s.strip
            field_name = trs[4].css('td')[7].text.to_s.strip
            field_no = trs[4].css('td')[8].text.to_s.strip

          
           csv << [lease_name, lease_no, well_no, well_type, operator_name, operator_num, field_name, field_no]


        end
    end

end