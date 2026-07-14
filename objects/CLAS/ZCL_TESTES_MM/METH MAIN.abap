  METHOD main.


*    DATA ls_nfeprot TYPE /exedminb/t_nfeprotocolo.
*    DATA lt_nfeprot TYPE TABLE OF /exedminb/t_nfeprotocolo.
*    ls_nfeprot-Id = '33250834274233026675550000022305591280489858'.
*    ls_nfeprot-tpAmb = '1'.
*    ls_nfeprot-verAplic = 'SVRS2507041437DR'.
*    ls_nfeprot-dhRecbto = '2025-08-07T22:51:13.0000000'.
*    ls_nfeprot-nProt = '233250297135705'.
*    ls_nfeprot-digVal = 'iYGCm1yYtgQFrr6d8nEu1ambRH4'.
*    ls_nfeprot-cStat = '100'.
*    ls_nfeprot-xMotivo = 'Autorizado o uso da NF-e'.
*    append ls_nfeprot to lt_nfeprot.
*
*    MODIFY /exedminb/t_nfeprotocolo FROM TABLE @lt_nfeprot.
*
*    EXIT.

*    select from /EXEDMINB/I_NFEMONITORH
*      fieLDS ChaveNFe
*      into table @data(lt_nfes).
*
*    modiFY enTITIES OF /EXEDMINB/I_NFEMONITORH
*      ENTITY _NFeMonitorH
*      DELETE FROM value #( for line in lt_nfes ( ChaveNFe = line-ChaveNFe ) ).
*
*      commIT eNTITIES.

   DATA xml TYPE xstring.
    /exedminb/cl_tax_integ_hub=>get_nfe_xml(
      EXPORTING
        i_accesskey   = '35250924502351000240550020003444941357111219'
      IMPORTING
        e_xml_xstring  = xml
    ).


    /exedminb/cl_tax_integ_hub=>extract_xml_save( i_xml_xstring = xml ).



    /exedminb/cl_tax_integ_hub=>get_nfe_xml(
      EXPORTING
        i_accesskey   = '33251034274233026675550000022421051120139950'
      IMPORTING
        e_xml_xstring  = xml
    ).


    /exedminb/cl_tax_integ_hub=>extract_xml_save( i_xml_xstring = xml ).


    /exedminb/cl_tax_integ_hub=>get_nfe_xml(
      EXPORTING
        i_accesskey   = '33251034274233026675550000022408541306337712'
      IMPORTING
        e_xml_xstring  = xml
    ).


    /exedminb/cl_tax_integ_hub=>extract_xml_save( i_xml_xstring = xml ).

    out->write( 'Fim' ).
*    /exedminb/cl_tax_integ_hub=>get_nfe_xml_list(
*      EXPORTING
**        i_nfemodel       =
*        i_startentrydate = '2026-02-10T08:00:27.016'
*        i_endentrydate   = '2026-02-13T08:00:27.016'
*      IMPORTING
**        e_xml_string     =
*        e_xml_xstring    = DATA(e_xml_xstring)
*        e_status         = DATA(status)
*    ).
*
*    CHECK e_xml_xstring IS NOT INITIAL.
*    /exedminb/cl_tax_integ_hub=>extract_xml_save( i_xml_xstring = e_xml_xstring ).

    out->write( 'Fim' ).
  ENDMETHOD.