class RRCCounty
    attr_accessor :current_page, :browser, :county, :start_page_num,
                  :browser, :url, :current_page, :raw_html_path

    def initialize(county, year, start_page_num)
        @county = county
        @start_page_num = start_page_num.to_i
        @browser = Watir::Browser.new(:ff) 
        @url = "http://webapps2.rrc.state.tx.us/EWA/productionQueryAction.do"
        @current_page = start_page_num.to_i
        @browser.goto(@url)
        @browser.radio(:value =>'Lease').set
        @browser.radio(:value => 'Both').set
        @browser.select_list(:name => 'searchArgs.startMonthArg').select('Jan')
        @browser.select_list(:name => 'searchArgs.startYearArg').select("#{year}")
        @browser.select_list(:name => 'searchArgs.endMonthArg').select('Dec')
        @browser.select_list(:name => 'searchArgs.endYearArg').select("#{year}")
        @browser.select_list(:name => 'searchArgs.onShoreCountyCodeArg').select("#{@county}")
        @browser.button(:value => 'Submit').click

        page = Nokogiri::HTML.parse(@browser.html)

        options = page.css("select[name='pager.pageSize'] option").collect

        options.each do |option|
            if option.text == '100'
                @browser.select_list(:name => 'pager.pageSize').select('100')
            elsif option.text == '50'
                @browser.select_list(:name => 'pager.pageSize').select('50')
            elsif option.text == '25'
                @browser.select_list(:name => 'pager.pageSize').select('25')
            else
                @browser.select_list(:name => 'pager.pageSize').select('View All')
            end
        end

        unless Dir.exists?(File.join(Rails.root, 'data', 'raw_html'))
            FileUtils::mkdir(File.join(Rails.root, 'data', 'raw_html'))
        end
        
        sleep(rand(1..5)*1.25)

        return @browser
    end

    def process_lease_link(links)

        links.each do |link, lease_num|
            
            @browser.link(:href, "#{link}").click
            @browser.select_list(:name => 'pager.pageSize').select('View All')
            write_ptd_page(Nokogiri::HTML.parse(@browser.html), lease_num)
            @browser.link(:text => /Disposition Details/).click

            sleep 1

            @browser.select_list(:name => 'pager.pageSize').select('View All')
            write_disp_page(Nokogiri::HTML.parse(@browser.html), lease_num)
            @browser.link(:text => /County Production/).click

            sleep 1

            write_cnty_pd_page(Nokogiri::HTML.parse(@browser.html), lease_num)
            @browser.link(:text => /County: #{Regexp.quote(@county)}/).click
            
        end

        next_page
        process_lease_page

        
    end

    def data_grid(page)
        lease_links = []
        lease_nums = []
        links = []
        

        lease_rows = page.css("table[class='DataGrid'] tr")
        lease_rows.each_with_index  do |row, index|
            
            if index > 2
                 if row.css('a')[0].nil? == false
                    lease_links << row.css('a')[0]["href"].to_s
                    lease_nums << row.css('td table tbody tr td')[0].text.to_s.chomp.strip
                    links = lease_links.zip( lease_nums )
                 end

            end 
        end

        process_lease_link(links)
    end

    def process_lease_page
        page = Nokogiri::HTML.parse(@browser.html)
            write_leases_page(page)
            data_grid(page)
    end
    

    def proceed_to_page_num
        click_next = @start_page_num - 1

        click_next.times do 
            next_page
            sleep 1
        end
        process_lease_page
    end



    def start
        if @start_page_num == 1
            process_lease_page
        else
            proceed_to_page_num
        end
    end


    private
    def write_leases_page(html)
        unless Dir.exists?(File.join(Rails.root, 'data', 'raw_html', @county))
            FileUtils::mkdir(File.join(Rails.root, 'data', 'raw_html', @county))
        end
        File.open(Rails.root + "data/raw_html/#{county}/#{@current_page}.html", 'w') { |f| f.write(html) } 
        @current_page += 1
    end

    def write_ptd_page(html, lease_num)
        unless Dir.exists?(File.join(Rails.root, 'data', 'raw_html', @county, 'leases', 'ptd'))
            FileUtils::mkdir_p(File.join(Rails.root, 'data', 'raw_html', @county, 'leases', 'ptd'))
        end
        File.open(Rails.root + "data/raw_html/#{@county}/leases/ptd/ptd_#{lease_num}.html", 'w') { |f| f.write(html) }
    end

    def write_disp_page(html, lease_num)
        unless Dir.exists?(File.join(Rails.root, 'data', 'raw_html', @county, 'leases', 'disp'))
            FileUtils::mkdir(File.join(Rails.root, 'data', 'raw_html', @county, 'leases', 'disp'))
        end
        File.open(Rails.root + "data/raw_html/#{@county}/leases/disp/disp_#{lease_num}.html", 'w') { |f| f.write(html) }
    end

    def write_cnty_pd_page(html, lease_num)
        unless Dir.exists?(File.join(Rails.root, 'data', 'raw_html', @county, 'leases', 'cnty_pd'))
            FileUtils::mkdir(File.join(Rails.root, 'data', 'raw_html', @county, 'leases', 'cnty_pd'))
        end
        File.open(Rails.root + "data/raw_html/#{@county}/leases/cnty_pd/cnty_pd_#{lease_num}.html", 'w') { |f| f.write(html) }
    end

    def next_page
        if @browser.link(:text => /Next/).exists?
            @browser.link(:text => /Next/).click
        else
            @browser.close
        end
    end

end

def get_lease_pages(county, year, start_page_num)
    scraper = RRCCounty.new(county, year, start_page_num)
    scraper.start   
end