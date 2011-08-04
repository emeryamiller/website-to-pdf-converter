#Site Converter

Converts a website (series of urls) into a pdf

Can be called as follows:

- For sequential urls where only a number changes from page to page.  For example, page-1.html, page-2.html, and so forth.  Note that the url provided should replace the number location with x (or whatever character is specified in the `by_replacing` call.

        convert(url).by_replacing('x').with(1..5).to(filename)

- If you have a list of urls already 

        convert(urls).to(filename) 

- If you need to follow a link that is named consistently (uses a regex match, so partial matches will work).

        convert(url).follwing_link('next').to(filename)

-  A more advanced use, passes a lambda function into the following_link method.  This allows you to utilize the power of mechanize to determine what link to follow (it provides the mechanize page object to you).  For example if the link you need to follow has some special attribute (a class, or a custom attribute) then you could do the following:

         convert(url).follwing_link(
            ->(page) {
                 page.links.find {|link| link.attributes['somehiddenattribute'] == 'somevalue' }
            }
         ).to(filename)

##Requirements:
- Mac OS X Snow Leopard and above 
- Macruby (> 0.10 - current head)
- Automator - the combine method uses automator to combine the downloaded pdfs into one
- ~/pdfs directory - this is where the pdfs are created and combined

##Thanks:

Thanks to Tom Ward's blog [post][screenshots] on taking screenshots with MacRuby and Brad Miller's [post][cocoa_pdfs] on creating PDF's in Cocoa. I combined these two approaches, and added the mechanize layer to navigate a site.

[screenshots]: http://tomafro.net/2009/11/taking-screenshots-of-web-pages-with-macruby
[cocoa_pdfs]: http://cocoadevcentral.com/articles/000074.php
