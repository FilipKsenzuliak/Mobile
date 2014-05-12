require 'net/http'
require 'nokogiri'
require 'set'
require 'mustache'
require 'open-uri'
 

  #@@name = 'http://alistapart.com/d/responsive-web-design/ex/ex-site-flexible.html'
  #source = Net::HTTP.get(URI(@@name))

  # saving name in class variable for further use
  


=begin

    # zistit linky ktore su o uroven nizsie
    right_menu = navigations.max_by{|k,v| v}[0] 
    @@nav_links = menu[right_menu.to_i].xpath(".//a")

    doc = Nokogiri::XML('
  <xml>
  <body>
  <image id="jno">imageeeeee</image>
  <text>text</text>
  <video>video</video>
  <other>other</other>
  <image>image</image>
  <text>text</text>
  <video>video</video>
  <other>other</other>
  </body>
  </xml>')

    doc.search('image[@id="jno"], text, video').each do |node|
          case node.name
          when 'image'
            puts node.text
          when 'text'
            puts node.text
          when 'video'
            puts node.text
          else
            puts 'should never get here'
          end
        end

=end

  # creating DOM from HTML document
  @@doc = Nokogiri::HTML(open("http://www.albert.cz/"))

  content = @@doc.xpath("//div[contains(@id, 'content') or
                                   contains(@id, 'Content') or
                                   contains(@id, 'obsah') or
                                   contains(@id, 'Obsah') or
                                   contains(@class, 'cont') or
                                   contains(@class, 'Content') or
                                   contains(@class, 'obsah') or
                                   contains(@class, 'Obsah')]")
 
  cn = Nokogiri::XML::NodeSet.new(@@doc,[])



    footers2 = @@doc.xpath("//div[contains (@id, 'foot') or
                                    contains (@id, 'paticka') or
                                    contains (@class, 'foot') or
                                    contains (@class, 'paticka')]")
    texts = footers2.xpath(".//*//text()")


    telephone = ''
    for i in 0...texts.size do
      nieco = texts[i].to_s.scan(/\+?\d[\d\s]+/).first
      puts nieco
      if nieco != nil
      if nieco.size > 8 && nieco.size < 15
        telephone = nieco
      end
      end
      #puts nieco
      #if 6 < nieco.size && nieco.size < 16
      #text = text.sub(nieco.to_s, "<a href='callTo:"+nieco.to_s.strip+"'>"+nieco.to_s+"</a>")
      #break
      #end
    end

    puts telephone


    #puts 'afaef +4655 15454 454 faefaef'.scan(/\+?[\d\s]/).join




#puts y.name
  # trimmed name
  
=begin 
  @@name = 'http://www.vodafone.cz/kontakty/'
  uri = URI(@@name)
  source = Net::HTTP.get(uri)
  @@doc = Nokogiri::HTML(source)
  # trimmed name
  @@page_name = (/.*\./.match(/[^\/]*/.match(@@name.sub(/^https?\:\/\//, '').sub(/^www./,'')).to_s).to_s)[0..-2]

  @@lines = Net::HTTP.get(uri).lines.count
  # making menu links so elsif they are in div it is more probable it is not content div
  @@nav_links = []
  @@content_images = []



    tel = @@doc.xpath("//*[contains (text(), '+420')]")
    tel += @@doc.xpath("//*[contains (text(), '+420')]")

    puts tel
    
=end
