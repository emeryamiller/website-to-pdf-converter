framework 'Cocoa'
framework 'WebKit'
framework 'Quartz'

class URL2PDF
  attr_accessor :options, :view, :window
  
  def initialize(options = {})
    @options = options
    initialize_view
  end
  
  def save(url, file)
    view.setFrameLoadDelegate(self)
    # Tell the webView what URL to load.
    frame = view.mainFrame
    req = NSURLRequest.requestWithURL(NSURL.URLWithString(url))
        frame.loadRequest req
    
    while view.isLoading  && !timed_out?
      NSRunLoop.currentRunLoop.runUntilDate NSDate.date
    end
    
    if @failedLoading
      puts "Failed to load page at: #{url}"
    else
      docView = view.mainFrame.frameView.documentView
      docView.window.setContentSize(docView.bounds.size)
      docView.setFrame(view.bounds)
    
      docView.setNeedsDisplay(true)
      docView.displayIfNeeded
      docView.lockFocus

      shared = NSPrintInfo.sharedPrintInfo.dictionary.dup
      shared[:NSJobDisposition] = "NSPrintSaveJob"
      shared[NSPrintSavePath] = file
      
      print_info = NSPrintInfo.alloc.initWithDictionary(shared)
      print_info.setHorizontalPagination NSAutoPagination
      print_info.setVerticalPagination NSAutoPagination
      print_info.setVerticallyCentered false

      print_op = NSPrintOperation.printOperationWithView(docView, printInfo:print_info)
      print_op.setShowPanels false
      print_op.runOperation
    
     # bitmap = NSBitmapImageRep.alloc.initWithFocusedViewRect(docView.bounds)
     # docView.unlockFocus

     # # Write the bitmap to a file as a PNG
     # representation = bitmap.representationUsingType(NSPNGFileType, properties:nil)
     # representation.writeToFile(file, atomically:true)
     # #bitmap.release
    end
  end
  
  private
  
  def webView(view, didFailLoadWithError:error, forFrame:frame)
    @failedLoading = true
  end
  
  def webView(view, didFailProvisionalLoadWithError:error, forFrame:frame)
    @failedLoading = true
  end
  
  def initialize_view
    NSApplication.sharedApplication    
    
    self.view = WebView.alloc.initWithFrame([0, 0, 1024, 600])
    self.window = NSWindow.alloc.initWithContentRect([0, 0, 1024, 600],
      styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)
      
    window.setContentView(view)    
    # Use the screen stylesheet, rather than the print one.
    view.setMediaStyle('screen')
    # Set the user agent to Safari, to ensure we get back the exactly the same content as 
    # if we browsed directly to the page
    view.setCustomUserAgent 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us)' +
        'AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10'
    # Make sure we don't save any of the prefs that we change.
    view.preferences.setAutosaves(false)
    # Set some useful options.
    view.preferences.setShouldPrintBackgrounds(true)
    view.preferences.setJavaScriptCanOpenWindowsAutomatically(false)
    view.preferences.setAllowsAnimatedImages(false)
    # Make sure we don't get a scroll bar.
    view.mainFrame.frameView.setAllowsScrolling(false)
  end
  
  def timed_out?
    @start ||= Time.now
    (Time.now.to_i - @start.to_i) > (options[:timeout] || 30)
  end
end

def combine_pdfs(directory, filename)
    final_pdf = PDFDocument.alloc.init

    Dir[File.expand_path(File.join(directory, '*.pdf'))].each do |file|
        url = NSURL.fileURLWithPath file
        current_pdf = PDFDocument.alloc.initWithURL url
        unless current_pdf
            puts "Couldn't open #{url.absoluteString}"
            next
        end
        (0...current_pdf.pageCount).each do |index|
            final_pdf.insertPage(current_pdf.pageAtIndex(index), atIndex:final_pdf.pageCount)
        end
    end
    final_pdf.writeToFile(File.expand_path(filename))
end
