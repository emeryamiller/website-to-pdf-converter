# 
# Converter:
#   Converts a website (series of urls) into a pdf
#   Can be called as follows:
#    
#    convert(url).by_replacing('x').with(1..5).to(filename) : Good for sequential urls where a number 
#                                                             changes from page to page
#
#    convert(urls).to(filename) : Good if you have a list of urls to convert. Maintains the ordering
#
#    convert(url).follwing_link('next').to(filename)        : Good for following text links from page to page
#
#    A more advanced use, passes a lambda function into the following_link method.  This allows you
#    to utilize the power of mechanize to determine what link to follow (it provides the mechanize page object
#    to you).  For example if the link you need to follow has some special attribute (a class, 
#    or a custom attribute) then you could do the following:
#
#    convert(url).follwing_link(
#       ->(page) {
#            page.links.find {|link| link.attributes['somehiddenattribute'] == 'somevalue' }
#       }
#    ).to(filename)
#
# Requires:
#   Mac (both macruby and automator are mac only)
#   Macruby (> 0.10 - current head is sufficient)
#   Automator - the combine method uses automator to combine the downloaded pdfs into one

require 'url2pdf'
require 'rubygems'
require 'mechanize'
require 'set'

class Converter
    def initialize(url)
        @convert = URL2PDF.new
        @filename = nil 
        @algorithm = nil

        @url = url
        @algorithm = :site_by_urls if @url.kind_of?(Array)
    end

    def to(filename)
        @filename = filename
        go if valid?
        self
    end

    def by_following(link_def)
        @algorithm = :site_by_link
        @link_def = link_def
        self
    end

    def by_replacing(replacement)
       @replacement = replacement 
       @algorithm = :site_by_url_index
       self
    end

    def with(range)
        @range = range
        self
    end

    def go
        @filename ||= "converted.pdf"
        self.send(@algorithm)
        combine
    end

    def valid?
        valid = false
        if @algorithm && !@url.empty?
            valid = true unless @algorithm == :site_by_url_index && @range == nil
        end
        valid
    end

    def site_by_link_(first_url, link_function)
       links = Set.new
       a = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
       next_link = first_url
       index = 0
       while next_link && links.add?(next_link)
          index+=1
          p = a.get(next_link) 
          @convert.save(next_link, "~/pdf/temp#{"%04d" % index}.pdf")
          link = link_function.call(p) 
          if link
              p = link.click
              next_link = p.uri.to_s
          else
              next_link = nil
          end
       end
    end

    def site_by_link
        link_function = @link_def
        link_function = -> (page) { page.link(text:/#{@link_def}/i) } if @link_def.kind_of?(String)
        site_by_link_(@url, link_function)
    end

    def site_by_url_index
       @range.each do |index|
           @convert.save(@url.gsub(@replacement, index.to_s), "~/pdf/temp#{"%04d" % index}.pdf")
       end
    end

    def site_by_urls
        @url.each_with_index {|url, index| @convert.save(url, "~/pdf/temp#{"%04d" % index}.pdf") }
    end

    def combine
        %x[automator -i ~/pdf /Users/emery/Library/Workflows/Custom/combine_pdfs.workflow]
    end

end

def convert(url)
    Converter.new(url)
end

