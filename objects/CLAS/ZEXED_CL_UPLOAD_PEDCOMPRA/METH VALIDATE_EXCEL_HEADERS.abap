  METHOD validate_excel_headers.

    rv_is_valid = abap_true.

*    DATA(ls_header_excel) = it_excel[ 1 ].
*
*    " Validar cada coluna do cabeçalho
*    IF    ls_header_excel-purchase_order       <> c_excel_headers-purchase_order
*       OR ls_header_excel-company_code      <> c_excel_headers-company_code
*       OR ls_header_excel-purchase_org <> c_excel_headers-purchase_org
*       OR ls_header_excel-purchase_grp        <> c_excel_headers-purchase_grp.
*
*      rv_is_valid = abap_false.
*
*    ENDIF.

  ENDMETHOD.