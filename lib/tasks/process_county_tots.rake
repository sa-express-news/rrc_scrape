def process_county_tots
    filenames = Dir[Rails.root.join('data', 'raw_html', '*', 'leases', 'cnty_pd', '*.html')]

    
    # filenames = [    '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/BEE/leases/cnty_pd/cnty_pd_09250.html', 
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_00428.html', 
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_00717.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_001029.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_001046.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_01260.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_02002.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_02031.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/LIVE OAK/leases/cnty_pd/cnty_pd_17034.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/MCMULLEN/leases/cnty_pd/cnty_pd_17034.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/LIVE OAK/leases/cnty_pd/cnty_pd_09944.html',
    #                  '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/cnty_pd/cnty_pd_09944.html'
    #               ]   


    CSV.open(Rails.root.join('data', 'processed', 'county_totals.csv'), "ab") do |csv|

        filenames.each do |file|
            puts file
            lease_no = file.match(/(?<=\_pd\/cnty_pd_)(.*?)(?=\.)/).to_s

            html = Nokogiri::HTML(File.open(file, 'r'))
       
            county_gw_prod = 0        
            county_chead_prod = 0

            deets_trs = html.css('table[class="TabBox2"] tbody tr')

            begin
              deets_td = deets_trs[1].css('td')
            rescue NoMethodError => e
              File.open(Rails.root.join('data', 'processed', 'errors.txt'), 'a') { |f| f.write("#{file}\n") }
              next
            end

            raw_deets = deets_td.text.gsub(/\n|\s|\u00a0/,'')
            county_name = raw_deets.match(/(?<=CountyName:).+(?=District:)/).to_s.gsub(/\s/,'')
            lease_name = raw_deets.match(/(?<=LeaseName:).+(?=,LeaseNo.:)/).to_s.gsub(/"|'|\//,'').strip
            well_type = raw_deets.match(/(?<=WellType:).+(?=CountyName:)/).to_s.strip
            dist_no = raw_deets.match(/(?<=District:).+(?=CountyProductionDateRange:)/).to_s.strip
            date = raw_deets.match(/(?<=CountyProductionDateRange:).+/).to_s.strip

            trs = html.css('table[class="DataGrid"] tbody tr')
            
            if trs[3].nil? == false
                trs[3].css('td').each_with_index do |td, idx|
                    if idx == 0
                        county_name = td.text.gsub(/\s/,'')
                    elsif idx == 1 && well_type == 'Gas'
                        county_gw_prod = td.text.gsub(/,/, '').to_i
                    elsif idx == 2 && well_type == 'Oil'
                        county_chead_prod = td.text.gsub(/,/, '').to_i
                    end
                end
            end

            csv << [ 'EWA', county_name, lease_no, lease_name, dist_no, well_type, date, county_gw_prod, county_chead_prod ]
            #p [ 'EWA', county_name, lease_no, lease_name, dist_no, well_type, date, county_gw_prod, county_chead_prod ]
        end
    end
end