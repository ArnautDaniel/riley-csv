# riley-csv
An experiment in the insane crevices of silverbeard's mind.

This project consists of making single programs that do one thing.  (hopefully well).

riley-csv.factor converts excel to iif for importing invoices to quickbooks (uses xlsxio to convert to csv first because I am not writing a xlsx parser right now)

riley-pdf.rkt takes some of the csv parsing from factor and uses it to generate a latex file,  it then sends this to the...

latex server in riley-pdf-serv.lisp which creates the pdf and sends the binary file back to racket which finally writes the file in the current directory

This will all be tied together by the final language I need to use...C!  For glueing factor and racket together.

4 languages.  Why?!  WHY!?
