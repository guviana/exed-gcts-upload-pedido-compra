CLASS lhc_purchaseorderitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR PurchaseOrderItem RESULT result.

ENDCLASS.

CLASS lhc_purchaseorderitem IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
      ENTITY PurchaseOrderItem
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_items)
      ENTITY PurchaseOrderItem BY \_Header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_purchase_orders).

    CHECK lt_items IS NOT INITIAL AND lt_purchase_orders IS NOT INITIAL.

    DATA(ls_po) = lt_purchase_orders[ 1 ].

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<fs_item>).
      IF ls_po-Status = zexed_bp_i_up_pdcmp=>c_msg_status_published.
        APPEND VALUE #(
            %tky            = <fs_item>-%tky
            %update         = if_abap_behv=>fc-o-disabled
        ) TO result.
      ELSE.
        APPEND VALUE #(
            %tky            = <fs_item>-%tky
            %update         = if_abap_behv=>fc-o-enabled
        ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_purchaseorder DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PurchaseOrder RESULT result.

    METHODS publish FOR MODIFY
      IMPORTING keys FOR ACTION PurchaseOrder~publish RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR PurchaseOrder RESULT result.

ENDCLASS.

CLASS lhc_purchaseorder IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%action-publish = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD publish.

    DATA lt_update TYPE TABLE FOR UPDATE zexed_i_up_pdcmp_h.
    DATA lt_keys LIKE keys.
    DATA lt_deep TYPE zexed_cl_pedcompra=>tt_cria_pedido_deep.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      IF <fs_key>-%is_draft = if_abap_behv=>mk-off.
        APPEND <fs_key> TO lt_keys.
      ENDIF.
    ENDLOOP.

    CHECK lt_keys[] IS NOT INITIAL.

    READ ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
         ENTITY PurchaseOrder
         ALL FIELDS WITH
         CORRESPONDING #( lt_keys )
         RESULT DATA(lt_po).

    IF lt_po[] IS NOT INITIAL.

      DELETE lt_po WHERE Status = zexed_bp_i_up_pdcmp=>c_msg_status_published.

      IF lt_po[] IS NOT INITIAL.

        SELECT *
        FROM zexed_i_up_pdcmp_i
        FOR ALL ENTRIES IN @lt_po
        WHERE ParentUUID = @lt_po-uuid
        INTO TABLE @DATA(lt_po_items).

        IF sy-subrc = 0.
          SELECT zexed_i_up_pdcmp_a~*
          FROM zexed_i_up_pdcmp_a
          INNER JOIN @lt_po_items AS poitem ON zexed_i_up_pdcmp_a~ParentUUID = poitem~uuid
          INTO TABLE @DATA(lt_po_acc_ass).
        ENDIF.

        lt_deep = CORRESPONDING #( lt_po ).

        LOOP AT lt_deep ASSIGNING FIELD-SYMBOL(<fs_deep>).
          LOOP AT lt_po_items ASSIGNING FIELD-SYMBOL(<fs_item>) WHERE ParentUUID = <fs_deep>-uuid.
            APPEND CORRESPONDING #( <fs_item> ) TO <fs_deep>-purchase_order_item ASSIGNING FIELD-SYMBOL(<fs_deep_item>).
            LOOP AT lt_po_acc_ass ASSIGNING FIELD-SYMBOL(<fs_acc_ass>) WHERE ParentUUID = <fs_item>-uuid.
              APPEND CORRESPONDING #( <fs_acc_ass> ) TO <fs_deep_item>-to_account_assignment.
            ENDLOOP.
          ENDLOOP.
        ENDLOOP.

        TRY.
            zexed_cl_pedcompra=>criar_pedido_deep(
                EXPORTING
                    it_deep = lt_deep
                IMPORTING
                    et_return = DATA(lt_return)
            ).

            LOOP AT lt_po ASSIGNING FIELD-SYMBOL(<fs_po>).
              DATA(lv_index) = sy-tabix.
              LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<fs_return>) WHERE row_index = lv_index.
                APPEND VALUE #(
                  %tky = <fs_po>-%tky
                  %msg = new_message_with_text(
                           severity = COND #(
                                        WHEN <fs_return>-msgty = 'I' THEN if_abap_behv_message=>severity-information
                                        WHEN <fs_return>-msgty = 'W' THEN if_abap_behv_message=>severity-warning
                                        WHEN <fs_return>-msgty = 'E' THEN if_abap_behv_message=>severity-error
                                        WHEN <fs_return>-msgty = 'S' THEN if_abap_behv_message=>severity-success
                                        ELSE if_abap_behv_message=>severity-none )
                         text     = <fs_return>-msg )
                ) TO reported-purchaseorder.
              ENDLOOP.

              " Atualizar o status do arquivo (após toda validação)
              APPEND VALUE #( %tky                        = <fs_po>-%tky
                              %data-Status                = COND #(
                                                              WHEN <fs_return>-msgty = 'E' THEN zexed_bp_i_up_pdcmp=>c_msg_status_error
                                                              WHEN <fs_return>-msgty = 'S' THEN zexed_bp_i_up_pdcmp=>c_msg_status_published
                                                              ELSE zexed_bp_i_up_pdcmp=>c_msg_status_not_published )
                              %data-CriticalityStatus     =  COND #(
                                                              WHEN <fs_return>-msgty = 'E' THEN 1
                                                              WHEN <fs_return>-msgty = 'S' THEN 3
                                                              ELSE 0 )
                              %data-PurchaseOrder         = COND #(
                                                              WHEN <fs_return>-msgty = 'S' THEN <fs_return>-new_po ELSE <fs_po>-PurchaseOrder  )
                              %control-Status             = if_abap_behv=>mk-on
                              %control-CriticalityStatus  = if_abap_behv=>mk-on
                              %control-PurchaseOrder      = if_abap_behv=>mk-on )
              TO lt_update.
            ENDLOOP.

          CATCH cx_web_http_client_error INTO DATA(lx_http).
            LOOP AT lt_po ASSIGNING <fs_po>.
              APPEND VALUE #(
                %tky = <fs_po>-%tky
                %msg = new_message_with_text(
                         severity = if_abap_behv_message=>severity-error
                       text     = |Erro HTTP Client ao criar Pedido: { lx_http->get_text( ) }| )
              ) TO reported-purchaseorder.

              " Atualizar o status do arquivo (após toda validação)
              APPEND VALUE #( %tky                        = <fs_po>-%tky
                              %data-Status                = zexed_bp_i_up_pdcmp=>c_msg_status_error
                              %data-CriticalityStatus     = 1
                              %control-Status             = if_abap_behv=>mk-on
                              %control-CriticalityStatus  = if_abap_behv=>mk-on )
              TO lt_update.
            ENDLOOP.

            MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
              ENTITY PurchaseOrder
              UPDATE FIELDS ( Status CriticalityStatus )
              WITH lt_update.

            RETURN.
          CATCH cx_http_dest_provider_error INTO DATA(lx_dest).
            LOOP AT lt_po ASSIGNING <fs_po>.
              APPEND VALUE #(
                %tky = <fs_po>-%tky
                %msg = new_message_with_text(
                         severity = if_abap_behv_message=>severity-error
                       text     = |Erro Destination Provider ao criar Pedido: { lx_dest->get_text( ) }| )
              ) TO reported-purchaseorder.

              " Atualizar o status do arquivo (após toda validação)
              APPEND VALUE #( %tky                        = <fs_po>-%tky
                              %data-Status                = zexed_bp_i_up_pdcmp=>c_msg_status_error
                              %data-CriticalityStatus     = 1
                              %control-Status             = if_abap_behv=>mk-on
                              %control-CriticalityStatus  = if_abap_behv=>mk-on )
              TO lt_update.
            ENDLOOP.

            MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
              ENTITY PurchaseOrder
              UPDATE FIELDS ( Status CriticalityStatus )
              WITH lt_update.

            RETURN.
        ENDTRY.

*        LOOP AT lt_po ASSIGNING <fs_po>.
*          DATA(lv_index) = sy-tabix.
*          READ TABLE lt_return ASSIGNING FIELD-SYMBOL(<fs_return>) INDEX lv_index.
*          IF <fs_return>-msgty = 'E'.
*            APPEND VALUE #(
*              %tky = <fs_po>-%tky
*              %msg = new_message_with_text(
*                       severity = if_abap_behv_message=>severity-error
*                       text     = <fs_return>-msg )
*            ) TO reported-purchaseorder.
*
*            " Atualizar o status do arquivo (após toda validação)
*            APPEND VALUE #( %tky                        = <fs_po>-%tky
*                            %data-Status                = zexed_bp_i_up_pdcmp=>c_msg_status_error
*                            %data-CriticalityStatus     = 1
*                            %control-Status             = if_abap_behv=>mk-on
*                            %control-CriticalityStatus  = if_abap_behv=>mk-on )
*            TO lt_update.
*          ELSE.
*            APPEND VALUE #(
*              %tky = <fs_po>-%tky
*              %msg = new_message_with_text(
*                       severity = if_abap_behv_message=>severity-success
*                       text     = <fs_return>-msg )
*            ) TO reported-purchaseorder.
*
*            " Atualizar o status do arquivo (após toda validação)
*            APPEND VALUE #( %tky                        = <fs_po>-%tky
*                            %data-Status                = zexed_bp_i_up_pdcmp=>c_msg_status_published
*                            %data-CriticalityStatus     = 3
*                            %control-Status             = if_abap_behv=>mk-on
*                            %control-CriticalityStatus  = if_abap_behv=>mk-on )
*            TO lt_update.
*          ENDIF.
*        ENDLOOP.
*
        IF lt_update IS NOT INITIAL.
          MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
            ENTITY PurchaseOrder
            UPDATE FIELDS ( Status CriticalityStatus PurchaseOrder )
            WITH lt_update.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
     ENTITY PurchaseOrder
     FIELDS ( Status )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_po_status).

    LOOP AT lt_po_status ASSIGNING FIELD-SYMBOL(<fs_po_status>).
      IF <fs_po_status>-Status = zexed_bp_i_up_pdcmp=>c_msg_status_published.
        APPEND VALUE #(
            %tky            = <fs_po_status>-%tky
            %update         = if_abap_behv=>fc-o-disabled
            %action-publish = if_abap_behv=>fc-o-disabled
        ) TO result.
      ELSE.
        APPEND VALUE #(
            %tky = <fs_po_status>-%tky
            %update         = if_abap_behv=>fc-o-enabled
            %action-publish = if_abap_behv=>fc-o-enabled
        ) TO result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zexed_i_up_pdcmp DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zexed_i_up_pdcmp IMPLEMENTATION.

  METHOD save_modified.

*  data ls_file type zexed_i_up_pdcmp.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_zexed_i_up_pdcmp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR File
        RESULT result,
      validateTemplate FOR DETERMINE ON MODIFY
        IMPORTING keys FOR File~validateTemplate,
      processFile FOR DETERMINE ON SAVE
        IMPORTING keys FOR File~processFile,
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR File RESULT result.
ENDCLASS.

CLASS lhc_zexed_i_up_pdcmp IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD validateTemplate.

    DATA lt_update TYPE TABLE FOR UPDATE zexed_i_up_pdcmp.
    DATA lt_excel  TYPE STANDARD TABLE OF zexed_cl_upload_pedcompra=>ty_excel.
    DATA lv_status TYPE string.

    READ ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
         ENTITY File
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT FINAL(lt_files).

    DATA(ls_file) = VALUE #( lt_files[ 1 ] OPTIONAL ).

    " Se não há arquivo
    IF ls_file-FileContent IS INITIAL.

      lv_status = zexed_bp_i_up_pdcmp=>c_msg_none.

      APPEND VALUE #( %tky = ls_file-%tky
                      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-warning
                                                    text     = 'Nenhum arquivo anexado' ) )
      TO reported-file.

    ELSE.

      " Há arquivo - validar
      DATA(lv_is_valid) = abap_true.

      TRY.
          zexed_cl_upload_pedcompra=>read_excel(
            EXPORTING
                iv_file_content = ls_file-FileContent
            IMPORTING
                et_excel_data   = lt_excel
                ev_is_valid     = lv_is_valid ).

        CATCH cx_abap_invalid_value.
          lv_is_valid = abap_false.

      ENDTRY.

*      " Validar cabeçalhos se a leitura foi bem-sucedida
*      IF lv_is_valid = abap_true.
*        lv_is_valid = zexed_cl_upload_pedcompra=>validate_excel_headers( it_excel = lt_excel ).
*      ENDIF.

      " Definir status baseado no resultado da validação
      IF lv_is_valid = abap_false.

        lv_status = zexed_bp_i_up_pdcmp=>c_msg_error.

        APPEND VALUE #( %tky = ls_file-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Arquivo com template inválido' ) )
        TO reported-file.

      ENDIF.

      LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<fs_excel_h>).
        LOOP AT <fs_excel_h>-to_items ASSIGNING FIELD-SYMBOL(<fs_excel_i>).
          LOOP AT <fs_excel_i>-to_account_assignment ASSIGNING FIELD-SYMBOL(<fs_excel_acc_ass>).
            DATA(lv_index_acc_ass) = sy-tabix.
            IF <fs_excel_i>-mult_acct_ass_dist = '' AND ( <fs_excel_acc_ass>-purg_doc_net_amount IS NOT INITIAL
                                                             OR <fs_excel_acc_ass>-quantity IS NOT INITIAL
                                                             OR <fs_excel_acc_ass>-mult_acct_assgmt_distr_percent IS NOT INITIAL
                                                            ).
              lv_status = zexed_bp_i_up_pdcmp=>c_msg_error.
              lv_is_valid = abap_false.

              APPEND VALUE #( %tky = ls_file-%tky
                              %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                            text     = |Class. Cont. { lv_index_acc_ass }: Informar rateio no item { <fs_excel_i>-item }| ) )
              TO reported-file.
            ELSEIF <fs_excel_i>-mult_acct_ass_dist = '1' AND <fs_excel_acc_ass>-quantity IS INITIAL.   "distrib. baseada em quantidade
              lv_status = zexed_bp_i_up_pdcmp=>c_msg_error.
              lv_is_valid = abap_false.

              APPEND VALUE #( %tky = ls_file-%tky
                              %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                            text     = |Distrib. baseada em quantidade, informar quantidade na class. cont. { lv_index_acc_ass }| ) )
              TO reported-file.
            ELSEIF <fs_excel_i>-mult_acct_ass_dist = '2' AND <fs_excel_acc_ass>-mult_acct_assgmt_distr_percent IS INITIAL. "distrib. baseada em percentual
              lv_status = zexed_bp_i_up_pdcmp=>c_msg_error.
              lv_is_valid = abap_false.

              APPEND VALUE #( %tky = ls_file-%tky
                              %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                            text     = |Distrib. baseada em percentual, informar percentual na class. cont. { lv_index_acc_ass }| ) )
              TO reported-file.
            ELSEIF <fs_excel_i>-mult_acct_ass_dist = '3' AND <fs_excel_acc_ass>-purg_doc_net_amount IS INITIAL. "distrib. baseada em valor
              lv_status = zexed_bp_i_up_pdcmp=>c_msg_error.
              lv_is_valid = abap_false.

              APPEND VALUE #( %tky = ls_file-%tky
                              %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                            text     = |Distrib. baseada em valor, informar valor na class. cont. { lv_index_acc_ass }| ) )
              TO reported-file.
            ENDIF.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.

      IF lv_is_valid = abap_true.
        lv_status = zexed_bp_i_up_pdcmp=>c_msg_ready.
*        APPEND VALUE #( %tky = ls_file-%tky
*                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
*                                                      text     = 'Arquivo processado com sucesso' ) )
*        TO reported-file.
      ENDIF.
    ENDIF.

    " Atualizar o status do arquivo (após toda validação)
    APPEND VALUE #( %tky                      = ls_file-%tky
                    %data-FileStatus          = lv_status
                    %data-CriticalityStatus   = COND #( WHEN lv_status = zexed_bp_i_up_pdcmp=>c_msg_error THEN 1 ELSE 2 )
                    %control-FileStatus       = if_abap_behv=>mk-on
                    %control-CriticalityStatus       = if_abap_behv=>mk-on )
    TO lt_update.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
        ENTITY File
        UPDATE FIELDS ( FileStatus CriticalityStatus )
        WITH lt_update.
    ENDIF.
  ENDMETHOD.

  METHOD processFile.

    DATA lt_update TYPE TABLE FOR UPDATE zexed_i_up_pdcmp.
    DATA lt_excel  TYPE TABLE OF zexed_cl_upload_pedcompra=>ty_excel.
    DATA lt_po_create TYPE TABLE FOR CREATE zexed_i_up_pdcmp\_PurchaseOrders.
    DATA lt_po_item_create TYPE TABLE FOR CREATE zexed_i_up_pdcmp_h\_Itens.
    DATA lt_po_acc_ass_create TYPE TABLE FOR CREATE zexed_i_up_pdcmp_i\_AccAssignment.
    DATA lv_percent TYPE p LENGTH 2 DECIMALS 1.
    DATA lv_net_amt TYPE p LENGTH 15 DECIMALS 2.

*    TYPES:
*      BEGIN OF ty_create_acc_ass,
*        item_uuid             TYPE sysuuid_x16,
*        to_account_assignment TYPE TABLE FOR CREATE zexed_i_up_pdcmp_i\_AccAssignment,
*      END OF ty_create_acc_ass.
*
*    DATA lt_po_acc_ass_create TYPE TABLE OF ty_create_acc_ass.
*    DATA ls_po_acc_ass_create LIKE LINE OF lt_po_acc_ass_create.

    READ ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
         ENTITY File
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT FINAL(lt_files).

    DATA(ls_file) = VALUE #( lt_files[ 1 ] OPTIONAL ).

    TRY.
        IF ls_file-FileContent IS NOT INITIAL.
          " Há arquivo - validar
          DATA(lv_is_valid) = abap_true.

          TRY.
              zexed_cl_upload_pedcompra=>read_excel(
                EXPORTING
                    iv_file_content = ls_file-FileContent
                IMPORTING
                    et_excel_data   = lt_excel
                    ev_is_valid     = lv_is_valid ).

            CATCH cx_abap_invalid_value.
              lv_is_valid = abap_false.

          ENDTRY.

          LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<fs_excel_h>).
            LOOP AT <fs_excel_h>-to_items ASSIGNING FIELD-SYMBOL(<fs_excel_i>).
              LOOP AT <fs_excel_i>-to_account_assignment ASSIGNING FIELD-SYMBOL(<fs_excel_acc_ass>).
                DATA(lv_index_acc_ass) = sy-tabix.
                IF <fs_excel_i>-mult_acct_ass_dist = '' AND ( <fs_excel_acc_ass>-purg_doc_net_amount IS NOT INITIAL
                                                                 OR <fs_excel_acc_ass>-quantity IS NOT INITIAL
                                                                 OR <fs_excel_acc_ass>-mult_acct_assgmt_distr_percent IS NOT INITIAL
                                                                ).
                  lv_is_valid = abap_false.

                  APPEND VALUE #( %tky = ls_file-%tky
                                  %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                                text     = |Class. Cont. { lv_index_acc_ass }: Informar forma de rateio no item { <fs_excel_i>-item }| ) )
                  TO reported-file.
                ELSEIF <fs_excel_i>-mult_acct_ass_dist = '1' AND <fs_excel_acc_ass>-quantity IS INITIAL.   "distrib. baseada em quantidade
                  lv_is_valid = abap_false.

                  APPEND VALUE #( %tky = ls_file-%tky
                                  %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                                text     = |Distrib. baseada em quantidade, informar quantidade na class. cont. { lv_index_acc_ass }| ) )
                  TO reported-file.
                ELSEIF <fs_excel_i>-mult_acct_ass_dist = '2' AND <fs_excel_acc_ass>-mult_acct_assgmt_distr_percent IS INITIAL. "distrib. baseada em percentual
                  lv_is_valid = abap_false.

                  APPEND VALUE #( %tky = ls_file-%tky
                                  %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                                text     = |Distrib. baseada em percentual, informar percentual na class. cont. { lv_index_acc_ass }| ) )
                  TO reported-file.
                ELSEIF <fs_excel_i>-mult_acct_ass_dist = '3' AND <fs_excel_acc_ass>-purg_doc_net_amount IS INITIAL. "distrib. baseada em valor
                  lv_is_valid = abap_false.

                  APPEND VALUE #( %tky = ls_file-%tky
                                  %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                                text     = |Distrib. baseada em valor, informar valor na class. cont. { lv_index_acc_ass }| ) )
                  TO reported-file.
                ENDIF.
              ENDLOOP.
            ENDLOOP.
          ENDLOOP.

          IF lv_is_valid = abap_true.
            CLEAR lt_po_create[].

            LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<fs_excel>).
              DATA(lv_index) = sy-tabix.
              CHECK <fs_excel> IS NOT INITIAL.

*              DATA(lv_uuid_po) = cl_system_uuid=>create_uuid_x16_static( ).

              APPEND VALUE #(
                 uuid  = ls_file-uuid
                 %is_draft = keys[ 1 ]-%is_draft
                 %target   = VALUE #( ( %cid      = |PO_{ <fs_excel>-purchase_order }|
                                        %is_draft = ls_file-%is_draft
                                        %data     = VALUE #(
*                                            uuid                 = lv_uuid_po
                                            ParentUUID           = ls_file-uuid
                                            PurchaseOrder        = <fs_excel>-purchase_order
                                            PurchaseOrderType2   = <fs_excel>-purchase_order_type
                                            PurchaseOrderDate    = <fs_excel>-purchase_order_date
                                            CompanyCode          = <fs_excel>-company_code
                                            PurchaseOrganization = <fs_excel>-purchase_org
                                            PurchaseGroup        = <fs_excel>-purchase_grp
                                            Supplier             = <fs_excel>-supplier
                                            PaymentTerms         = <fs_excel>-payment_terms
                                            Status               = zexed_bp_i_up_pdcmp=>c_msg_status_not_published
                                            CriticalityStatus    = 2
                                          )
                                        %control = VALUE #(
*                                            uuid           = if_abap_behv=>mk-on
                                            ParentUUID           = if_abap_behv=>mk-on
                                            PurchaseOrder        = if_abap_behv=>mk-on
                                            PurchaseOrderType2   = if_abap_behv=>mk-on
                                            PurchaseOrderDate    = if_abap_behv=>mk-on
                                            CompanyCode          = if_abap_behv=>mk-on
                                            PurchaseOrganization = if_abap_behv=>mk-on
                                            PurchaseGroup        = if_abap_behv=>mk-on
                                            Supplier             = if_abap_behv=>mk-on
                                            PaymentTerms         = if_abap_behv=>mk-on
                                            Status               = if_abap_behv=>mk-on
                                            CriticalityStatus    = if_abap_behv=>mk-on
                                          )

                                      ) ) ) TO lt_po_create ASSIGNING FIELD-SYMBOL(<fs_po_create>).

*              LOOP AT <fs_excel>-to_items ASSIGNING FIELD-SYMBOL(<fs_excel_item>).
*                DATA(lv_index_item) = sy-tabix.
*                APPEND VALUE #(
**                   uuid  = lv_uuid_po
*                   uuid = ls_file-uuid
*                   %is_draft = keys[ 1 ]-%is_draft
*                   %target   = VALUE #( ( %cid      = |{ <fs_excel>-purchase_order }{ lv_index_item }|
*                                          %is_draft = ls_file-%is_draft
*                                          %data     = VALUE #(
*                                              uuid                  = cl_system_uuid=>create_uuid_x16_static( )
*                                              FileUUID              = ls_file-uuid
**                                              ParentUUID            = lv_uuid_po
*                                              PurchaseOrder         = <fs_excel_item>-purchase_order
*                                              Item                  = <fs_excel_item>-item
*                                              Material              = <fs_excel_item>-material
*                                              Plant                 = <fs_excel_item>-plant
*                                            )
*                                          %control = VALUE #(
*                                              uuid              = if_abap_behv=>mk-on
*                                              FileUUID          = if_abap_behv=>mk-on
*                                              ParentUUID        = if_abap_behv=>mk-on
*                                              PurchaseOrder     = if_abap_behv=>mk-on
*                                              Item              = if_abap_behv=>mk-on
*                                              Material          = if_abap_behv=>mk-on
*                                              Plant             = if_abap_behv=>mk-on
*
*                                            )
*                                        ) ) ) TO lt_po_item_create.
*              ENDLOOP.
            ENDLOOP.

            IF lt_po_create[] IS NOT INITIAL.
              " Atualizar o status do arquivo (após toda validação)
              APPEND VALUE #( %tky                      = ls_file-%tky
                              %data-FileStatus          = zexed_bp_i_up_pdcmp=>c_msg_uploaded
                              %data-CriticalityStatus   = 3
                              %control-FileStatus       = if_abap_behv=>mk-on
                              %control-CriticalityStatus       = if_abap_behv=>mk-on )
              TO lt_update.

              MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
                ENTITY File
                UPDATE FIELDS ( FileStatus CriticalityStatus )
                WITH lt_update
                CREATE BY \_PurchaseOrders
                AUTO FILL CID
                WITH lt_po_create
*                ENTITY PurchaseOrder
*                CREATE BY \_Itens
*                AUTO FILL CID
*                WITH lt_po_item_create
                MAPPED DATA(lt_mapped_items)
                FAILED DATA(lt_failed_items)
                REPORTED DATA(lt_reported_items).


              " Se houver falhas, reportar
              IF lt_failed_items IS NOT INITIAL.
                APPEND VALUE #(
                  %tky = ls_file-%tky
                  %msg = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = 'Erro ao criar pedidos de compra. Verifique os dados.' )
                ) TO reported-file.
              ELSE.
                APPEND VALUE #( %tky = ls_file-%tky
                                %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                              text     = 'Arquivo processado com sucesso' ) )
                TO reported-file.
              ENDIF.
            ENDIF.

            LOOP AT lt_mapped_items-purchaseorder ASSIGNING FIELD-SYMBOL(<fs_mapped_po>).
              lv_index = sy-tabix.

              READ TABLE lt_excel ASSIGNING <fs_excel> INDEX lv_index.

              CHECK sy-subrc = 0.

              LOOP AT <fs_excel>-to_items ASSIGNING FIELD-SYMBOL(<fs_excel_item>).
                DATA(lv_index_item) = sy-tabix.
                DATA(lv_item_uuid) = cl_system_uuid=>create_uuid_x16_static( ).

                APPEND VALUE #(
                   uuid  = <fs_mapped_po>-uuid
                   %is_draft = keys[ 1 ]-%is_draft
                   %target   = VALUE #( ( %cid      = |PO_{ <fs_excel_item>-purchase_order }ITEM_{ <fs_excel_item>-item }|
                                          %is_draft = ls_file-%is_draft
                                          %data     = VALUE #(
                                              uuid                              = lv_item_uuid
                                              ParentUUID                        = <fs_mapped_po>-uuid
                                              FileUUID                          = ls_file-uuid
                                              PurchaseOrder                     = <fs_excel_item>-purchase_order
                                              Item                              = <fs_excel_item>-item
                                              Material                          = <fs_excel_item>-material
                                              Plant                             = <fs_excel_item>-plant
                                              DocumentCurrency                  = <fs_excel_item>-document_currency
                                              PurchaseOrderQuantityUnit         = <fs_excel_item>-purchase_order_quantity_unit
                                              NetPriceAmount                    = <fs_excel_item>-net_price_amount
                                              OrderQuantity                     = <fs_excel_item>-order_quantity
                                              PurchaseRequisition               = <fs_excel_item>-purchase_requisition
                                              PurchaseRequisitionItem           = <fs_excel_item>-purchase_requisition_item
                                              BaseUnit                          = <fs_excel_item>-base_unit
                                              MultipleAcctAssgmtDistribution    = <fs_excel_item>-mult_acct_ass_dist
                                              AccountAssignmentCategory         = <fs_excel_item>-account_assignment_category
                                              TaxCode                           = <fs_excel_item>-tax_code
                                            )
                                          %control = VALUE #(
                                              uuid                            = if_abap_behv=>mk-on
                                              ParentUUID                      = if_abap_behv=>mk-on
                                              FileUUID                        = if_abap_behv=>mk-on
                                              PurchaseOrder                   = if_abap_behv=>mk-on
                                              Item                            = if_abap_behv=>mk-on
                                              Material                        = if_abap_behv=>mk-on
                                              Plant                           = if_abap_behv=>mk-on
                                              DocumentCurrency                = if_abap_behv=>mk-on
                                              PurchaseOrderQuantityUnit       = if_abap_behv=>mk-on
                                              NetPriceAmount                  = if_abap_behv=>mk-on
                                              OrderQuantity                   = if_abap_behv=>mk-on
                                              PurchaseRequisition             = if_abap_behv=>mk-on
                                              PurchaseRequisitionItem         = if_abap_behv=>mk-on
                                              BaseUnit                        = if_abap_behv=>mk-on
                                              MultipleAcctAssgmtDistribution  = if_abap_behv=>mk-on
                                              AccountAssignmentCategory       = if_abap_behv=>mk-on
                                              TaxCode                         = if_abap_behv=>mk-on
                                            )
                                        ) ) ) TO lt_po_item_create.

                IF <fs_excel_item>-to_account_assignment IS NOT INITIAL.
*                  CLEAR ls_po_acc_ass_create.
*                  ls_po_acc_ass_create-item_uuid = lv_item_uuid.

                  LOOP AT <fs_excel_item>-to_account_assignment ASSIGNING FIELD-SYMBOL(<fs_excel_accass>).
                    DATA(lv_index_accass) = sy-tabix.

                    APPEND VALUE #(
                       uuid  = lv_item_uuid
                       %is_draft = keys[ 1 ]-%is_draft
                       %target   = VALUE #( ( %cid      = |PO_{ <fs_excel_accass>-purchase_order }ITEM_{ <fs_excel_accass>-item }ACCASS_{ lv_index_accass }|
                                              %is_draft = ls_file-%is_draft
                                              %data     = VALUE #(
                                                  uuid                              = cl_system_uuid=>create_uuid_x16_static( )
                                                  ParentUUID                        = lv_item_uuid
                                                  FileUUID                          = ls_file-uuid
                                                  PurchaseOrder                     = <fs_excel_accass>-purchase_order
                                                  Item                              = <fs_excel_accass>-item
                                                  AccountAssignmentNumber           = lv_index_accass
                                                  CostCenter                        = <fs_excel_accass>-cost_center
                                                  ProjectNetwork                    = <fs_excel_accass>-project_network
                                                  NetworkActivity                   = <fs_excel_accass>-network_activity
                                                  OrderQuantityUnit                 = <fs_excel_accass>-order_quantity_unit
                                                  Quantity                          = <fs_excel_accass>-quantity
                                                  DocumentCurrency                  = <fs_excel_accass>-document_currency
                                                  PurgDocNetAmount                  = <fs_excel_accass>-purg_doc_net_amount
                                                  MultipleAcctAssgmtDistrPercent    = <fs_excel_accass>-mult_acct_assgmt_distr_percent
                                                  GLAccount                         = <fs_excel_accass>-glaccount
                                                )
                                              %control = VALUE #(
                                                  uuid                              = if_abap_behv=>mk-on
                                                  ParentUUID                        = if_abap_behv=>mk-on
                                                  FileUUID                          = if_abap_behv=>mk-on
                                                  PurchaseOrder                     = if_abap_behv=>mk-on
                                                  Item                              = if_abap_behv=>mk-on
                                                  AccountAssignmentNumber           = if_abap_behv=>mk-on
                                                  CostCenter                        = if_abap_behv=>mk-on
                                                  ProjectNetwork                    = if_abap_behv=>mk-on
                                                  NetworkActivity                   = if_abap_behv=>mk-on
                                                  OrderQuantityUnit                 = if_abap_behv=>mk-on
                                                  Quantity                          = if_abap_behv=>mk-on
                                                  DocumentCurrency                  = if_abap_behv=>mk-on
                                                  PurgDocNetAmount                  = if_abap_behv=>mk-on
                                                  MultipleAcctAssgmtDistrPercent    = if_abap_behv=>mk-on
                                                  GLAccount                         = if_abap_behv=>mk-on
                                                )
*                                            ) ) ) TO ls_po_acc_ass_create-to_account_assignment.

                                            ) ) ) TO lt_po_acc_ass_create.
                  ENDLOOP.

*                  APPEND ls_po_acc_ass_create TO lt_po_acc_ass_create.
                ENDIF.
              ENDLOOP.
            ENDLOOP.

            IF lt_po_item_create[] IS NOT INITIAL.
              MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
                ENTITY PurchaseOrder
                CREATE BY \_Itens
                AUTO FILL CID
                WITH lt_po_item_create
                MAPPED DATA(lt_mapped_po_items)
                FAILED DATA(lt_failed_po_items)
                REPORTED DATA(lt_reported_po_items).


              " Se houver falhas, reportar
              IF lt_failed_po_items IS NOT INITIAL.
                APPEND VALUE #(
                  %tky = ls_file-%tky
                  %msg = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = 'Erro ao criar itens do pedido de compras. Verifique os dados.' )
                ) TO reported-file.
              ELSE.
                MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
                  ENTITY PurchaseOrderItem
                  CREATE BY \_AccAssignment
                  AUTO FILL CID
                  WITH lt_po_acc_ass_create
                  MAPPED DATA(lt_mapped_acc_ass)
                  FAILED DATA(lt_failed_acc_ass)
                  REPORTED DATA(lt_reported_acc_ass).

                IF lt_failed_acc_ass IS NOT INITIAL.
                  APPEND VALUE #(
                    %tky = ls_file-%tky
                    %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = 'Erro ao criar class. contab. dos itens do pedido de compras. Verifique os dados.' )
                  ) TO reported-file.
                ENDIF.
              ENDIF.
            ENDIF.
          ELSE.
            " Se o template for inválido, reportar erro
            APPEND VALUE #(
              %tky = ls_file-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = 'O template do arquivo Excel é inválido.' )
            ) TO reported-file.

*            " Atualizar o status do arquivo para erro
*            APPEND VALUE #( %tky                      = ls_file-%tky
*                            %data-FileStatus          = zexed_bp_i_up_pdcmp=>c_msg_error
*                            %data-CriticalityStatus   = 1
*                            %control-FileStatus       = if_abap_behv=>mk-on
*                            %control-CriticalityStatus       = if_abap_behv=>mk-on )
*            TO lt_update.
*
*            MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
*              ENTITY File
*              UPDATE FIELDS ( FileStatus CriticalityStatus )
*              WITH lt_update.
          ENDIF.
        ENDIF.
      CATCH cx_root INTO DATA(lx_root).
        " Em caso de erro fatal no processamento, reportar falha
        APPEND VALUE #(
          %tky = ls_file-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Erro inesperado ao processar o arquivo Excel.' )
        ) TO reported-file.

*        " Atualizar o status do arquivo para erro
*        APPEND VALUE #( %tky                      = ls_file-%tky
*                        %data-FileStatus          = zexed_bp_i_up_pdcmp=>c_msg_error
*                        %data-CriticalityStatus   = 1
*                        %control-FileStatus       = if_abap_behv=>mk-on
*                        %control-CriticalityStatus       = if_abap_behv=>mk-on )
*        TO lt_update.
*
*        MODIFY ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
*          ENTITY File
*          UPDATE FIELDS ( FileStatus CriticalityStatus )
*          WITH lt_update.
    ENDTRY.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zexed_i_up_pdcmp IN LOCAL MODE
         ENTITY File
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT FINAL(lt_files)
         ENTITY File BY \_PurchaseOrders
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_purchase_orders).

    LOOP AT lt_files ASSIGNING FIELD-SYMBOL(<fs_file>).
      DATA(lv_count_pub) = 0.

      LOOP AT lt_purchase_orders ASSIGNING FIELD-SYMBOL(<fs_po>) WHERE ParentUUID = <fs_file>-uuid.
        IF <fs_po>-Status = zexed_bp_i_up_pdcmp=>c_msg_status_published.
          lv_count_pub += 1.
        ELSE.

        ENDIF.

        IF lv_count_pub > 0 AND lv_count_pub = lines( lt_purchase_orders ).
          DATA(lv_action_enabled) = if_abap_behv=>fc-o-disabled.
        ELSE.
          lv_action_enabled = if_abap_behv=>fc-o-enabled.
        ENDIF.

        APPEND VALUE #(
            %is_draft  = <fs_file>-%is_draft
            uuid       = <fs_file>-uuid
            %update    = lv_action_enabled
       ) TO result.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.