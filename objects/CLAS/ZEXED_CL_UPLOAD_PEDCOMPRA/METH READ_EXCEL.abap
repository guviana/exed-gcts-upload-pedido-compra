  METHOD read_excel.

    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_struc_descr TYPE REF TO cl_abap_structdescr.
    DATA lv_no_cols     TYPE i.
    DATA lt_excel_po_h TYPE gt_excel_po_h.
    DATA lt_excel_po_i TYPE gt_excel_po_i.
    DATA ls_excel_po_i LIKE LINE OF lt_excel_po_i.
    DATA lt_excel_po_i_acc  TYPE gt_excel_po_i_acc.
    DATA ls_excel_po_i_acc  LIKE LINE OF lt_excel_po_i_acc.
    DATA: ls_excel_data LIKE LINE OF et_excel_data.

    ev_is_valid = abap_true.

    CLEAR: lt_excel_po_h, lt_excel_po_i.

    TRY.
        " Criar documento Excel a partir do conteúdo do arquivo
        DATA(lo_document) = xco_cp_xlsx=>document->for_file_content( iv_file_content = iv_file_content ).

        " Obter acesso de leitura ao documento
        DATA(lo_xlsx) = lo_document->read_access( ).

        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "WORKSHEET PedidoCompra
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        " Obter a primeira planilha
        DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->for_name( 'PedidoCompra' ).

        " Criar padrão de seleção para ler todas as linhas e colunas
        DATA(lo_pattern_builder) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

        " Executar operação de leitura e escrever na tabela interna
        DATA(lo_operation) = lo_worksheet->select( io_pattern = lo_pattern_builder
        )->row_stream( )->operation->write_to( it_internal_table = REF #( lt_excel_po_h ) ).

        " Definir transformação de valor para string
        lo_operation->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
        )->if_xco_xlsx_ra_operation~execute( ).

        " Obter descritor da tabela e estrutura
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel_po_h ).
        lo_struc_descr ?= lo_table_descr->get_table_line_type( ).

        " Obter número de colunas
        lv_no_cols = lines( lo_struc_descr->components ).

        " Verificar se a tabela contém dados
        IF lt_excel_po_h[] IS INITIAL.
          ev_is_valid = abap_false.
          RETURN.
        ENDIF.

        " Verificar se a primeira linha contém dados
        DATA(ls_excel_po_h) = VALUE #( lt_excel_po_h[ 1 ] OPTIONAL ).
        IF ls_excel_po_h IS INITIAL.
          ev_is_valid = abap_false.
          RETURN.
        ENDIF.

*        " Verificar se o número de colunas é correto (deve ser 4 conforme template)
*        IF lv_no_cols <> 4.
*          ev_is_valid = abap_false.
*          RETURN.
*        ENDIF.

        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "WORKSHEET Item
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        " Obter a primeira planilha
        lo_worksheet = lo_xlsx->get_workbook( )->worksheet->for_name( 'Item' ).

        " Criar padrão de seleção para ler todas as linhas e colunas
        lo_pattern_builder = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

        " Executar operação de leitura e escrever na tabela interna
        lo_operation = lo_worksheet->select( io_pattern = lo_pattern_builder
        )->row_stream( )->operation->write_to( it_internal_table = REF #( lt_excel_po_i ) ).

        " Definir transformação de valor para string
        lo_operation->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
        )->if_xco_xlsx_ra_operation~execute( ).

        " Obter descritor da tabela e estrutura
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel_po_i ).
        lo_struc_descr ?= lo_table_descr->get_table_line_type( ).

        " Obter número de colunas
        lv_no_cols = lines( lo_struc_descr->components ).

*        " Verificar se a tabela contém dados
*        IF lt_excel_po_i[] IS INITIAL.
*          ev_is_valid = abap_false.
*          RETURN.
*        ENDIF.

*        " Verificar se a primeira linha contém dados
*        DATA(ls_excel_po_i) = VALUE #( lt_excel_po_i[ 1 ] OPTIONAL ).
*        IF ls_excel_po_i IS INITIAL.
*          ev_is_valid = abap_false.
*          RETURN.
*        ENDIF.

*        " Verificar se o número de colunas é correto (deve ser 3 conforme template)
*        IF lv_no_cols <> 3.
*          ev_is_valid = abap_false.
*          RETURN.
*        ENDIF.

        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "WORKSHEET Class.Contabil
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        " Obter a primeira planilha
        lo_worksheet = lo_xlsx->get_workbook( )->worksheet->for_name( 'Class.Contabil' ).

        " Criar padrão de seleção para ler todas as linhas e colunas
        lo_pattern_builder = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

        " Executar operação de leitura e escrever na tabela interna
        lo_operation = lo_worksheet->select( io_pattern = lo_pattern_builder
        )->row_stream( )->operation->write_to( it_internal_table = REF #( lt_excel_po_i_acc ) ).

        " Definir transformação de valor para string
        lo_operation->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
        )->if_xco_xlsx_ra_operation~execute( ).

        " Obter descritor da tabela e estrutura
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel_po_i_acc ).
        lo_struc_descr ?= lo_table_descr->get_table_line_type( ).

        " Obter número de colunas
        lv_no_cols = lines( lo_struc_descr->components ).

        "deleta linha de cabecalho
        DELETE lt_excel_po_h INDEX 1.
        DELETE lt_excel_po_i INDEX 1.
        DELETE lt_excel_po_i_acc INDEX 1.
        DELETE lt_excel_po_h WHERE purchase_order IS INITIAL.
        DELETE lt_excel_po_i WHERE purchase_order IS INITIAL.
        DELETE lt_excel_po_i_acc WHERE purchase_order IS INITIAL.

        LOOP AT lt_excel_po_h ASSIGNING FIELD-SYMBOL(<fs_excel_po_h>).
          CLEAR ls_excel_data.
          ls_excel_data = CORRESPONDING #( <fs_excel_po_h> ).
          ls_excel_data-purchase_order = |%{ ls_excel_data-purchase_order }|.   "temp key before publish

          ls_excel_data-purchase_order_date = convert_excel_date( CONV i( ls_excel_data-purchase_order_date ) )-data_dats.

          LOOP AT lt_excel_po_i ASSIGNING FIELD-SYMBOL(<fs_excel_po_i>) WHERE purchase_order = <fs_excel_po_h>-purchase_order.
            CLEAR ls_excel_po_i.
            ls_excel_po_i = CORRESPONDING #( <fs_excel_po_i> ).
            ls_excel_po_i-purchase_order = |%{ ls_excel_po_i-purchase_order }|.   "temp key before publish

            IF ls_excel_po_i-base_unit IS NOT INITIAL.
              ls_excel_po_i-base_unit = zexed_cl_conv_exit_cunit=>convert_input( CONV #( ls_excel_po_i-base_unit ) ).
            ENDIF.

            IF ls_excel_po_i-purchase_order_quantity_unit IS NOT INITIAL.
              ls_excel_po_i-purchase_order_quantity_unit = zexed_cl_conv_exit_cunit=>convert_input( CONV #( ls_excel_po_i-purchase_order_quantity_unit ) ).
            ENDIF.

            LOOP AT lt_excel_po_i_acc ASSIGNING FIELD-SYMBOL(<fs_excel_po_i_acc>) WHERE purchase_order = <fs_excel_po_i>-purchase_order
                                                                                    AND item = <fs_excel_po_i>-item.

              CLEAR ls_excel_po_i_acc.
              ls_excel_po_i_acc = CORRESPONDING #( <fs_excel_po_i_acc> ) .
              ls_excel_po_i_acc-purchase_order = |%{ ls_excel_po_i_acc-purchase_order }|.   "temp key before publish

              IF ls_excel_po_i_acc-order_quantity_unit  IS NOT INITIAL.
                ls_excel_po_i_acc-order_quantity_unit = zexed_cl_conv_exit_cunit=>convert_input( CONV #( ls_excel_po_i_acc-order_quantity_unit  ) ).
              ENDIF.

              APPEND ls_excel_po_i_acc TO ls_excel_po_i-to_account_assignment.
            ENDLOOP.

            APPEND ls_excel_po_i TO ls_excel_data-to_items.
          ENDLOOP.

          APPEND ls_excel_data TO et_excel_data.
        ENDLOOP.

        ev_is_valid = abap_true.

      CATCH cx_uom_error.
        ev_is_valid = abap_false.

      CATCH cx_static_check.
        ev_is_valid = abap_false.

      CATCH cx_root.
        ev_is_valid = abap_false.

    ENDTRY.

  ENDMETHOD.