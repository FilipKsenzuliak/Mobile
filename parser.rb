require 'net/http'
require 'nokogiri'
require 'mustache'
require 'open-uri'
require 'iconv'

class Extractor < Mustache
  self.path = File.dirname(__FILE__)

  def initialize(name)
  #@@name = 'http://alistapart.com/d/responsive-web-design/ex/ex-site-flexible.html'
  #source = Net::HTTP.get(URI(@@name))

  # saving name in class variable for further use
  @@name = name
  
  # creating DOM from HTML document
  @@doc = Nokogiri::HTML(open(@@name))

  # trimmed name
  @@page_name = (/.*\./.match(/[^\/]*/.match(@@name.sub(/^https?\:\/\//, '').sub(/^www./,'')).to_s).to_s)[0..-2]

  # counting all lines of document
  @@lines = Net::HTTP.get(URI(@@name)).lines.count

  # navigation links will be stored here for further use in content rating
  @@nav_links = []
  end

  # method that rates navigations
  # @param menu - NodeSet(array of nodes) which may contain navigation
  # return navigation with highest score in array of hashes
  def rate_navigation(menu)
    navigations = Hash.new
    links_data = Array.new 

    # rating menus for links they contain
    for i in 0...menu.size do
      # set every hash for menus to 0 points
      navigations["#{i}"] = 0
      links = menu[i].xpath(".//a")
      for t in 0...links.size do
        hrefs = links[t].xpath(".//@href")

        # chcecking if text in menu contains word 'home'
        navigations["#{i}"] += 500 if links[t].xpath(".//text()").to_s.match(/^home$/i)
        # matching home href='/'
        if /^\/$|(^\.\/$)/.match(hrefs.to_s)
          # checking if it is not only one link in whole menu
          navigations["#{i}"] += 500 if links.size < 1
        # matching home link
        elsif hrefs.to_s.match(/index\.(php)$|index\.(html)$/)
          navigations["#{i}"] += 50
        # matching link starting with './', '/', or !http
        elsif (/^([\w]+(\.[\w]+)+.*)$|(^\/\w.*)|(^\.\/.*$)/).match(hrefs.to_s)
          navigations["#{i}"] += 20
        # matching if href contains webpage name
        elsif hrefs.to_s.include? @@page_name
          navigations["#{i}"] += 1
        end
      end
    end

    right_menu = navigations.max_by{|k,v| v}[0] 

    if menu[right_menu.to_i].xpath(".//a").size != 0
      @@nav_links = menu[right_menu.to_i].xpath(".//a")
      size = @@nav_links[1].path.split('/').size
      count = 0

      # checking if menu has another level of navigation
      until count == @@nav_links.size
      name = ''
      sign = false 
      is_link = true
      not_link = true

        # checking if it is parent link
        if @@nav_links[count].path.split('/').size == size
          previous_node = @@nav_links[count]   
            # getting parent node of link and its children 
            until name == 'li' || name =='td'
                if previous_node.class != Nokogiri::HTML::Document
                previous_node = previous_node.parent
                name = previous_node.name
                else
                  not_link = false
                  break 
                end    
            end

            if not_link == true
              lnks = previous_node.xpath('.//a')
              another_level = []
              # getting all data from children links
              for i in 0...lnks.size
                if lnks.size != 1
                  text = lnks[i].xpath(".//text()").to_s
                  href = lnks[i].xpath(".//@href").to_s
                  another_level << {:l_url => href, :l_text => text} if !(text =~ /^\s*$/)
                end
              end
                      
              # checking if parent has any children links
              sign = true if another_level.size != 0
              is_link = false if another_level.size != 0
                      
              # filling hash with all data
              href = @@nav_links[count].xpath(".//@href").to_s
              text = @@nav_links[count].xpath(".//text()").to_s
              links_data << {:url => href, 
                             :text => text, 
                             :has_levels => sign, 
                             :is_link => is_link, 
                             :level => another_level}
            end
        end

      count += 1
      end
    else
      links_data = nil 
    end

    ar = Array.new
    for i in 0...@@nav_links.size 
      ar << @@nav_links[i].path.split('/').size
    end 
    ar = ar.uniq

    # chceking if menu was found right
    # sending data to template
    if ar.size > 4
      data = Array.new
      for i in 0...@@nav_links.size
        data << {:url => @@nav_links[i].xpath('.//@href'), 
                       :text => @@nav_links[i].xpath('.//text()')}
      end
      data
    else
      links_data
    end
  end

  # method that gets structures with possible navigations
  # return navigation in array of hashes
  def navigation
  	menuSign = true
    links_data = []

    # checking best case scenario when navigation is in HTML5 nav tag
    if menuSign == true
      # getting nav nodes
      menu = @@doc.xpath("//nav")
      
      unless menu.size == 0
        links_data = rate_navigation(menu) 
        menuSign = false unless links_data == nil
      end
    end

    # if no nav tags were found
    if menuSign == true 
    	# getting divs where id contains any substring 'menu' or 'nav'
      menu2 = @@doc.xpath("//div[contains(@id, 'menu') or
                                 contains(@id, 'Menu') or
                                 contains(@id, 'nav') or
                                 contains(@id, 'Nav') or 
                                 contains(@class, 'menu') or 
                                 contains(@class, 'Menu') or 
                                 contains(@class, 'nav') or 
                                 contains(@class, 'Nav')]")     

      unless menu2.size == 0
        links_data = rate_navigation(menu2) 
        menuSign = false unless links_data == nil
      end
    end

    # if no divs with id 'menu' or 'nav' were found
    if menuSign == true 
      # getting ul,ol structures in which might be navigation  
      menu3 = @@doc.xpath("//ul")
      menu3 += @@doc.xpath("//ol")

      unless menu3.size == 0
        links_data = rate_navigation(menu3) 
        menuSign = false unless links_data == nil
      end
    end

    # chceking the worst case scenario when page might be built using tables
    if menuSign == true
      # getting tables in which might be navigation
      menu4 = @@doc.xpath("//table")
      menu4 += @@doc.xpath("//tbody")

      unless menu4.size == 0
        links_data = rate_navigation(menu4) 
        menuSign = false unless links_data == nil
      end
    end
    # filling menu in template
    links_data
  end

  # method getting logo of page
  # returns hash with informations of logo source and href
  def logo 
    logo = @@doc.xpath("//div[contains(@id, 'logo')]")
    logo += @@doc.xpath("//div[contains(@class, 'logo')]")
    # najdenie href = .... skript
    logo_href = logo.xpath(".//a//@href")
    logo_src = logo.xpath(".//img//@src")

    lg = @@doc.at_xpath("//*[contains(@src, 'logo')]")
    #lg += @@doc.xpath("//*[contains(@style, 'logo')]")

    # checking if any logo was found
    if logo_src.size != 0
      template_logo = Hash.new
      template_logo[:written] = false
      if logo_href.size != 0 
        template_logo[:href] = logo_href.to_s
        template_logo[:href_sign] = true
      end
      template_logo[:src] = @@name + logo_src.to_s
      template_logo[:image] = true
    else 
      template_logo = Hash.new
      template_logo[:image] = false
    end

    if lg != nil
      template_logo = Hash.new
      template_logo[:written] = false
      link = lg.parent
        
        template_logo[:href] = link.xpath('.//@href').to_s
        template_logo[:href_sign] = true

      template_logo[:src] = @@name + link.xpath('.//@src').to_s
      template_logo[:image] = true
    end

    # if no logo was found then make home with domain name 
    if template_logo[:image] == false && lg == nil
      template_logo[:written] = true
      template_logo[:name] = @@name
      template_logo[:src] = @@page_name.capitalize
    end

    # sending logo info into template
    template_logo
  end

  def images # nehladat image v contente + nie je iste ze parent img je <a> + skusit spravit [^/] negaciu pri hladani
             # nehladat image ani logo
             # ak source nema '/' tak ho pridat
             # koncovku .gif zahodit
=begin
    images = []
    template_images = []

    # checking if these images are not glyphicons
    @@doc.xpath("//img").each do |item|
      if item.xpath(".//@width").to_s.to_i == 0 or
         (item.xpath(".//@width").to_s.to_i > 30 and
          item.xpath(".//@height").to_s.to_i > 30) 
        images << item
      end
    end

    cnt_img = @@doc.xpath("//img")
    images = (@@content_images - cnt_img) | (cnt_img - @@content_images)

    for i in 0..images.size-1 do
      href = images[i].parent.xpath(".//@href").to_s
      if /^\/[\w\/]*/.match(href)
        href = @@name + href
      end
      src = images[i].xpath(".//@src").to_s

      if /^http?.*/.match(images[i].xpath(".//@src").to_s)
        template_images << {:src => src,
                            :href => href}
      else
        # matching address for format http://.... until first occurence of /
        template_images << {:src => (/^http\:\/\/[\w.-]*/.match(@@name)).to_s + '/' + src,
                            :href => href}
      end
    end
    template_images
=end
  end

  # method that rate contents and remove noisy parts
  # @param content - NodeSet(array of nodes) which may contain content
  # return content with highest rating as string
  def rate_content(content)
    contents = Hash.new
    for i in 0...content.size
      contents["#{i}"] = 0.0

      # chceking if div does not contain whole document
      contents["#{i}"] += -20 if content[i].to_s.lines.count > @@lines*0.95

      # rating contents for tags they contain
      contents["#{i}"] += 0.3*content[i].xpath(".//span").size   if content[i].xpath(".//span").size != 0
      contents["#{i}"] += 2*content[i].xpath(".//p").size        if content[i].xpath(".//p").size != 0
      contents["#{i}"] += 0.5*content[i].xpath(".//img").size    if content[i].xpath(".//img").size != 0
      contents["#{i}"] += 1*content[i].xpath(".//h3").size       if content[i].xpath(".//h3").size != 0
      contents["#{i}"] += 0.6*content[i].xpath(".//br").size     if content[i].xpath(".//br").size != 0
      contents["#{i}"] += 0.4*content[i].xpath(".//strong").size if content[i].xpath(".//strong").size != 0
      contents["#{i}"] += 0.4*content[i].xpath(".//em").size     if content[i].xpath(".//em").size != 0
      contents["#{i}"] += 0.5*content[i].xpath(".//h2").size     if content[i].xpath(".//h2").size != 0
      contents["#{i}"] += 0.4*content[i].xpath(".//b").size      if content[i].xpath(".//b").size != 0
      contents["#{i}"] += 0.2*content[i].xpath(".//h1").size     if content[i].xpath(".//h1").size != 0
      contents["#{i}"] += 2*content[i].xpath(".//article").size  if content[i].xpath(".//article").size != 0

      #checking if div does not contain navigation links
      for j in 0...@@nav_links.size do
        contents["#{i}"] += -2 if content[i].to_s.include? @@nav_links[j].to_s
      end

    end

    right_content = contents.max_by{|k,v| v}[0]

    cnt = content[right_content.to_i]
    clear(cnt)
  end

  def clear(cnt)
    page = ''
    image = cnt.xpath(".//img")
    ul = cnt.xpath(".//ul")

    # removing iframes
    cnt.search('.//iframe').each do |node|
      node.remove
    end

    # removing forms
    cnt.search('.//form').each do |node|
      node.remove
    end

    # removing objects
    cnt.search('.//object').each do |node|
      node.remove
    end

    # removing scripts
    cnt.search('.//script').each do |node|
      node.remove
    end

    page = contacts(cnt)

    # removing fixed measurements
    page = page.gsub(/width\=\"\d*(px)\"/,'')
    page = page.gsub(/width\=\"\d*\%\"/,'')
    page = page.gsub(/height\=\"\d*(px)\"/,'')
    page = page.gsub(/height\=\"\d*\%\"/,'')

    # correcting image sources
    for i in 0...image.size do 
      img = image[i].xpath('.//@src').to_s
      original_img = img
      # replacing & with &amp; so it can match original page's string
      if original_img.include? '&'
        original_img = original_img.sub('&','&amp;')
        img = img.sub('&','&amp;')
      end 

      # chcecking if src starts with http
      if !img.match(/^(http)/)
        if !img.start_with?('/')
          img = '/' + img
        end
        # correcting page's links sources
        page = page.gsub(original_img,'http://'+/[^\/]*/.match(@@name.gsub(/^https?\:\/\//, '')).to_s+img)
      end
    end

    # removing empty ul/li tags
    for i in 0...ul.size do
      li = ul[i].xpath(".//li")
      if ul[i].xpath('.//text()').to_s.match(/^\s*$/)
        page = page.sub(ul[i].to_s, '')
      end
      for j in 0...li.size do
        if li[j].xpath('.//text()').to_s.match(/^\s*$/)
          page = page.sub(li[j].to_s, '')
        end
      end
    end    
    
    # getting document that ignores non utf-8 chars
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    page = ic.iconv(page)  
    page
  end

  # method making possible phone numbers in content callable by adding href tel link
  # @param cnt - node which contains content
  # return string of page with callable tel numbers
  def contacts (cnt)
      page = ''
      page = cnt.to_s

      texts = cnt.xpath(".//*//text()") if cnt != nil
      telephone = ''
      if texts != nil
        for i in 0...texts.size do
          number = texts[i].to_s.scan(/\+?\d[\d\s]+\d/).first
          email = texts[i].to_s.scan(/\w[\w.]*\@\w+\.[a-zA-Z]{2,3}/).first

          if number != nil
            if number.to_s.size > 8 and number.to_s.size < 19
              telephone = number
              page = page.sub(telephone.to_s,"<a href='tel:"+telephone.to_s.strip+"'>"+telephone.to_s+"</a>")
            end
          end

          if email != nil
              page = page.sub(email.to_s,"<a href='mailTo:"+email.to_s.strip+"'>"+email.to_s+"</a>")
          end

        end
      end

      return page
  end

  def content
    divs = @@doc.xpath("//div")  
    paragraphs = Hash.new    
    navigations = Hash.new
    continue = false

    # MAIN TAG HTML 5    
    content = @@doc.xpath("//main")

    # getting divs where attribute id/class contains 'contnet' or 'obsah'
    if content.size == 0
      content = @@doc.xpath("//div[contains(@id, 'content') or
                                   contains(@id, 'Content') or
                                   contains(@id, 'obsah') or
                                   contains(@id, 'Obsah') or
                                   contains(@class, 'cont') or
                                   contains(@class, 'Content') or
                                   contains(@class, 'obsah') or
                                   contains(@class, 'Obsah')]")
      continue = true if content.size == 0
    end

    if content.size != 0
      cn = Nokogiri::XML::NodeSet.new(@@doc,[])

      sign = true
      for k in 0...content.size
        sign = true
        for j in 0...@@nav_links.size do
          sign = false if content[k].to_s.include? @@nav_links[j].to_s
        end
        if sign == true
          cn << content[k] unless cn.to_s.include? content[k].to_s
        end
      end

      page = ''
      for i in 0...cn.size
        page += clear(cn[i])
      end

      if page.lines.count < 30
        continue = true 
      else
        return page
      end
    end

    if continue == true
      return rate_content(@@doc.xpath('//div')) if @@doc.xpath('//div').size != 0
    end

  end

  def rate_footer(footer)
    footers = Hash.new

    # rating footers
    for i in 0...footer.size
      texts = footer[i].xpath(".//text()")
      footers["#{i}"] = 0.0
      
      footers["#{i}"] += 1*footer[i].xpath(".//a").size     if footer[i].xpath(".//a").size != 0
      footers["#{i}"] += 0.5*footer[i].xpath(".//h3").size  if footer[i].xpath(".//h3").size != 0
      footers["#{i}"] += 10                                 if texts.to_s.match(/^\+?[\d\s]{6,12}\d$/)
      footers["#{i}"] += 10                                 if texts.to_s.match(/^\w[\w.]*\@\w+\.[a-zA-Z]{2,3}$/)
    end

    right_footers = footers.max_by{|k,v| v}[0]


    page = ''
    ft = footer[right_footers.to_i]

    # getting tel / email from footer
    contact = Hash.new
    contact = get_contact(ft)

    images = ft.xpath(".//img")

    # removing images from footer
    ft.search('.//img').each do |node|
      node.remove
    end

    # removing forms
    ft.search('.//form').each do |node|
      node.remove
    end

    page = ft.to_s
    @@foot = ft

    # sending footer data
    page_data = Hash.new
    page_data[:page] = page
    page_data[:telephone] = contact[:telephone]
    page_data[:has_phone] = false
    page_data[:has_phone] = true if contact[:telephone].size > 0
    page_data[:email] = contact[:email]
    page_data[:has_email] = false
    page_data[:has_email] = true if contact[:email].size > 0

    page_data
  end 

  def get_contact(foot)
    texts = foot.xpath(".//*//text()") if foot != nil

    contact = Hash.new
    telephone = ''
    email = ''

    if texts != nil
      for i in 0...texts.size do
        number = texts[i].to_s.scan(/\+?\d[\d\s]+/).first
        mail = texts[i].to_s.scan(/\w[\w.]*\@\w+\.[a-zA-Z]{2,3}/).first
        
        if number != nil
          telephone = number if number.size > 8 and number.size < 18
        end

        if mail != nil
          email = texts[i].to_s.scan(/\w[\w.]*\@\w+\.[a-zA-Z]{2,3}/).first
        end
      end
    end

    contact[:telephone] = telephone
    contact[:email] = email

    contact
  end

  def footer
    sign = true

    # checking best case scenario with footer tag
    if sign == true
      footers = @@doc.xpath("//footer")
      if footers.size == 0
        sign = false 
      else
        return footers[0].to_s
      end
    end

    # if no footer tag was found checking for id/class containing foot or paticka
    if sign == false
      footers2 = @@doc.xpath("//div[contains (@id, 'foot') or
                                    contains (@id, 'paticka') or
                                    contains (@class, 'foot') or
                                    contains (@class, 'paticka')]")

      rate_footer(footers2) unless footers2.size == 0
    end
    
  end

  def charset
    charset = @@doc.at_xpath("//meta//@charset")
    charset.to_s
  end
=begin
  def telephone
    footers2 = @@doc.xpath("//div[contains (@id, 'foot') or
                                    contains (@id, 'paticka') or
                                    contains (@class, 'foot') or
                                    contains (@class, 'paticka')]")
    texts = footers2[0].xpath(".//*//text()") if footers2[0] != nil
    telephone = ''
    if texts != nil
      for i in 0...texts.size do
        number = texts[i].to_s.scan(/\+?\d[\d\s]+/).first
        
        if number != nil
          telephone = number if number.size > 8 and number.size < 15
        end
      end
    end

    telephone
  end

  def email
    footers2 = @@doc.xpath("//div[contains (@id, 'foot') or
                                    contains (@id, 'paticka') or
                                    contains (@class, 'foot') or
                                    contains (@class, 'paticka')]")
    texts = footers2[0].xpath(".//*//text()") if footers2[0] != nil
    email = ''
    if texts != nil
      for i in 0...texts.size do
        email = texts[i].to_s if texts[i].to_s.match(/^\w[\w.]*\@\w+\.[a-zA-Z]{2,3}$/)
      end
    end
    email
  end
=end 

end

#Extractor.new.navigation
#Extractor.new.images
#Extractor.new.logo
#mobile_page = Extractor.new("http://www.britannica.com/").render if $0 == __FILE__
#File.open('mobilePage.html', 'w') do |item|
#  item.puts mobile_page
#end


# ****** NAVIGATION *********
# napravit linky href
# redirektnut linky z navigacie na funkcne stranky

# ****** IMAGES **********
# skontrolovat ci image href nie je cela adresa a nie len relativna

# ****** CONTENT **********
# rozlisovat ci dat cely cont alebo len casti ak cely tak pozriet ci sa neprekriva obsah
# ak je content roztrhnuty vo viacerich tagoch
# siroke tabulky hadzat pod seba
# opravit este href imagom
# upravit este src na imagoch
