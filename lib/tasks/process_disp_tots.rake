def process_disp_tots
    filenames = Dir[Rails.root.join('data', 'raw_html', '*', 'leases', 'disp', '*.html')]



    # filenames = [ '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/disp/disp_02286.html', 
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/disp/disp_002258.html', 
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/disp/disp_09908.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/disp/disp_000229.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/disp/disp_02909.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/KARNES/leases/disp/disp_004536.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/LIVE OAK/leases/disp/disp_001516.html',
    #               '/Users/josephkokenge/sa/rrc_scrape/data/raw_html/LIVE OAK/leases/disp/disp_001519.html', 
    #               ]

    months = ['Jan2014', 
              'Feb2014',  
              'Mar2014', 
              'Apr2014', 
              'May2014', 
              'Jun2014', 
              'Jul2014', 
              'Aug2014', 
              'Sep2014', 
              'Oct2014', 
              'Nov2014', 
              'Dec2014']

    CSV.open(Rails.root.join('data', 'processed', 'disp_totals.csv'), 'ab') do |csv|
      filenames.each do |file|
        puts file

        lease_no = file.match(/(?<=\_)(\d*?)(?=\.)/).to_s
      
        html = Nokogiri::HTML(File.open(file, 'r'))

        deets_trs = html.css('table[class="TabBox2"] tbody tr')
        deets_td = deets_trs[1].css('td')
        raw_deets = deets_td.text.gsub(/\n|\s|\u00a0/,'')
        county_name = raw_deets.match(/(?<=CountyName:).+(?=District:)/).to_s.strip.gsub(/\s/, '')
        lease_name = raw_deets.match(/(?<=LeaseName:).+(?=,LeaseNo.:)/).to_s.gsub(/"|'|\//,'').strip
        well_type = raw_deets.match(/(?<=WellType:).+(?=CountyName:)/).to_s.strip
        dist_no = raw_deets.match(/(?<=District:).+(?=LeaseProductionandDispositionDateRange:)/).to_s.strip
        
        trs = html.css('table[class="DataGrid"] tbody tr')
        
        trs.each do |tr|
          date = ''
          chead_prod = 0
          chead_fv = 0

          gw_prod = 0
          gw_fv = 0

          tds = tr.css('td[align="right"]')
          
          tds.each_with_index do |td, idx|
          
            text = td.text.chomp.strip.gsub(/\n|\s|\t|,/,'')
           
            if months.include?(text) == true
              date = text
            end

            if idx == 13 && well_type == 'Oil'
              chead_prod = text
              chead_prod  == "NORPT" ? chead_prod = 0 : chead_prod
            elsif idx == 1 && well_type == 'Gas'
              gw_prod = text
              gw_prod == "NORPT" ? gw_prod = 0 : gw_prod
            end

            if idx == 17 && well_type == 'Oil'
              chead_fv = text
              chead_fv == '' ? chead_fv = 0 : chead_fv
            elsif idx == 5 && well_type == 'Gas'
              gw_fv = text
              gw_fv == '' ? gw_fv = 0 : gw_fv
            end
          end#tds do

          unless date.empty? 
            csv <<  [ county_name, lease_no, lease_name, dist_no, well_type, date, chead_prod.to_i, chead_fv.to_i, gw_prod.to_i, gw_fv.to_i   ]
            # p [ county_name, lease_no, lease_name, dist_no, well_type, date, chead_prod.to_i, chead_fv.to_i, gw_prod.to_i, gw_fv.to_i  ]
          end

        end#trs
      end#filenames
    end#csv
end