framework 'Cocoa'
framework 'Quartz'

module PDFUtils
    def combine_pdfs(pdf_paths, filename)
        final_pdf = PDFDocument.alloc.init

        Array(pdf_paths).each do |file|
            url = NSURL.fileURLWithPath File.expand_path(file)
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
end
