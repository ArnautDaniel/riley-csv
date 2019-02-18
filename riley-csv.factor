! Copyright (C) 2019 Your name.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays assocs io io.encodings.utf8 io.files kernel namespaces
sequences sequences.deep sequences.extras sets splitting locals  ;
IN: riley-csv

! So dirty
! Needs support for dirty commas
! Don't repeat yourself eh?
! TODO: Add support for running the command line
! argument file instead of test.csv

: riley-get-data ( path -- seq )
    utf8 <file-reader> stream-lines ;

: riley-split-seq ( seq -- seq1 seq2 )
    { 13 } split-indices dup first swap second ;

: riley-perfect-split ( item -- splititem )
    [ 44 = ] split-when ;

: riley-show-and-set ( seq  -- seq' )
    [ first dup "PROJECT:" equal? swap
      "SET:" equal? or ] filter flatten
    [ "" equal? ] reject dup second swap dup fourth
    swap 5 swap nth 3array ;


: riley-perfect-data ( seq -- seq' )
    [ riley-perfect-split  ] map
    [ second "" equal? ] reject  ;

CONSTANT: riley-invitem-header 
{ "!INVITEM" "NAME" "INVITEMTYPE" "DESC" "PURCHASEDESC" "ACCNT" "ASSETACCNT" "COGSACCNT" "PRICE" "COST" "TAXABLE" "PAYMETH" "TAXVEND" "TAXDIST" "PREFVEND" "REORDERPOINT" "EXTRA" }

: riley-accnt-header ( -- seq )
    { "!ACCNT" "NAME" "ACCNTTYPE" "DESC" "ACCNUM" "EXTRA" } ;

: riley-class-header ( -- seq )
    { "!CLASS" "NAME" } ;

: riley-spl-header ( -- seq )
    { "!SPL" "SPLID" "TRNSTYPE" "DATE" "ACCNT" "NAME" "CLASS" "AMOUNT" "DOCNUM" "MEMO" "CLEAR" "QNTY" "PRICE" "INVITEM" "TAXABLE" "EXTRA" } ;

: riley-trns-header ( -- seq )
    { "!TRNS" "TRNSID" "TRNSTYPE" "DATE" "ACCNT" "NAME" "CLASS" "AMOUNT" "DOCNUM" "MEMO" "CLEAR" "TOPRINT" "NAMEISTAXABLE" "ADDR1" "ADDR3" "TERMS" "SHIPVIA" "SHIPDATE" } ;

: riley-cust-header ( -- seq )
    { "!CUST" "NAME" "BADDR1" "BADDR3" "BADDR4" "BADDR5" "SADDR1" "SADDR2" "SADDR3" "SADDR4" "SADDR5" "PHONE1" "PHONE2" "FAXNUM" "EMAIL" "NOTE" "TERMS" "TAXABLE" "LIMIT" "SALUTATION" "COMPANYNAME" "FIRSTNAME" "MIDINIT" "LASTNAME" } ;

: riley-inv-name ( -- seq )
    { "NAME" "DESC" } ;

: riley-inv-template ( -- seq )
    { "NAME" "DESC" "PRICE" } ;

: riley-spl-template ( -- seq )
    { "MEMO" "INVITEM" "QNTY" "PRICE" } ;

: riley-inv-index ( -- seq )
    { 0 2 } ;

: riley-trns-index ( -- seq )
    { 5 } ;

: riley-filter-inv ( seq -- seq' )
    [ riley-inv-index member? swap drop ] filter-index ;

:: riley-replace ( seq item newval -- seq' )
    seq item [ equal? ] curry find drop
    seq swap [ = [ drop newval ] [ ] if ] curry map-index ;

: riley-add-static-invoice ( seq -- seq' )
    "!INVITEM" "INVITEM" riley-replace
    "INVITEMTYPE" "part" riley-replace ;

: riley-add-static-trns ( seq -- seq' )
    "!TRNS" "TRNS" riley-replace
    "TRNSTYPE" "INVOICE" riley-replace ;

: riley-add-static-spl ( seq -- seq' )
    "!SPL" "SPL" riley-replace
    "TRNSTYPE" "INVOICE" riley-replace
    "CLEAR" "N" riley-replace
    "TAXABLE" "Y" riley-replace ;

: prepare-invoice-item ( seq -- seq' )
    riley-filter-inv dup first prefix
    riley-inv-template swap zip ;

: riley-clear-by-member ( seq -- seq' )
    [ dup riley-invitem-header in? [ drop "" ] when ] map ;

: riley-trns-clear ( seq -- seq' )
    [ dup riley-trns-header in? [ drop "" ] when ] map ;

: riley-spl-clear ( seq -- seq' )
    [ dup riley-spl-header in? [ drop "" ] when ] map ;

:: individual-invoice-change ( str -- x )
    riley-invitem-header 
    str first str second
    riley-replace ;

: and-change-invoice-table ( seq -- invoiceitem )
    [ individual-invoice-change riley-clear-by-member ] map
    riley-invitem-header riley-add-static-invoice
    riley-clear-by-member
    [
        [
            append
        ] 2map
    ] reduce ;

: riley-tab-print ( seq -- )
    [ "\t" write ] [ write ] interleave "" print ;

: write-invoice-header ( -- )
    riley-invitem-header riley-tab-print ;

: write-invoice-lines ( seq -- )
    write-invoice-header
    [ riley-tab-print ] each ;

: write-class-lines ( -- )
    "!CLASS\tNAME" print
    "CLASS\tclass" print ;

:: individual-spl-change ( str -- x )
    riley-spl-header
    str first str second
    riley-replace ;

: write-spl-line ( seq -- )
    rest dup first prefix
    [ "" equal? ] reject
    riley-spl-template swap zip
    [ individual-spl-change riley-spl-clear ] map
    riley-spl-header riley-add-static-spl
    riley-spl-clear 
    [ [ append ] 2map ] reduce
    riley-tab-print ;
    
    
: write-spl-lines ( seq -- )
    [ write-spl-line ] each ;

: write-transaction-header ( -- )
    riley-trns-header riley-tab-print
    riley-spl-header riley-tab-print
    "!ENDTRNS" print ;

: write-transaction ( seq -- )
    riley-trns-header swap first "NAME" swap riley-replace
    riley-add-static-trns
    riley-trns-clear
    riley-tab-print ;

: riley-temp ( -- )
    "test.csv" riley-get-data riley-split-seq
    [ riley-perfect-data riley-show-and-set ] dip
    riley-perfect-data dup
    [
        rest prepare-invoice-item 
        and-change-invoice-table
    ] map
    "test.iif" utf8
    [
        write-invoice-lines
        write-class-lines
        write-transaction-header
        [ write-transaction ] dip
        write-spl-lines
        "ENDTRNS" print
    ] with-file-writer ;



