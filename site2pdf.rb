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
require 'fileutils'
require 'tempfile'

class Converter
    def initialize(url)
        @convert = URL2PDF.new
        @tmpdir = File.join(Dir.tmpdir, 'pdfs')
        @pdf_files = []
        @url = url
        @algorithm = :site_by_urls if @url.kind_of?(Array)
        FileUtils.makedirs @tmpdir
    end

    def to(filename)
        @filename = File.expand_path(filename)
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
        @filename ||= File.expand_path("~/converted.pdf")
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

    private

    def site_by_link
       links = Set.new
       links.add nil #To ensure nil can't be added again

       find_link = @link_def
       find_link = -> (page) { page.link(text:/#{@link_def}/i) } if @link_def.kind_of?(String)

       a = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
       next_url = @url
       while next_url && links.add?(next_url)
          p = a.get(next_url) 
          @convert.save(next_url, next_tempfile)

          next_url = nil
          link = find_link.call(p) 
          if link
              p = link.click
              next_url = p.uri.to_s
          end
       end
    end

    def site_by_url_index
       @range.each do |value|
           @convert.save(@url.gsub(@replacement, value.to_s), next_tempfile)
       end
    end

    def site_by_urls
        @url.each {|url, index| @convert.save(url, next_tempfile) }
    end

    def combine
        combine_pdfs(@pdf_files.map(&:path), @filename)
        @pdf_files.map(&:unlink)
    end

    def next_tempfile
      tmpfile = Tempfile.new(['converter', '.pdf'], @tmpdir)
      tmpfile.close
      @pdf_files << tmpfile
      tmpfile.path
    end
end

def convert(url)
    Converter.new(url)
end

