  METHOD convert_excel_date.

    DATA: lv_base_date TYPE d VALUE '18991230',  " 30/12/1899 (base do Excel)
          lv_abap_date TYPE d.

    CLEAR rs_conversion.

    " Validar entrada
    IF iv_excel_date <= 0.
      rs_conversion-data_formatted = ''.
      rs_conversion-data_dats = '00000000'.
      RETURN.
    ENDIF.

    TRY.
        " Converter número de série para data ABAP (YYYYMMDD)
        lv_abap_date = lv_base_date + iv_excel_date.

        " Retornar data em formato DATS
        rs_conversion-data_dats = lv_abap_date.

        rs_conversion-data_formatted = |{ lv_abap_date+6(2) }/{ lv_abap_date+4(2) }/{ lv_abap_date+0(4) }|.

      CATCH cx_root.
        " Em caso de erro, retornar datas vazias
        rs_conversion-data_formatted = ''.
        rs_conversion-data_dats = '00000000'.

    ENDTRY.


  ENDMETHOD.