  METHOD criar_pedido_deep.

*    TYPES: tt_purorder_items_create TYPE TABLE FOR CREATE i_purchaseordertp_2\_purchaseorderitem,
*           ty_purorder_items_create TYPE LINE OF tt_purorder_items_create.
*    TYPES: tt_item_account_assign_create TYPE TABLE FOR CREATE I_PurchaseOrderItemTP_2\_PurOrdAccountAssignment,
*           ty_item_account_assign_create TYPE LINE OF tt_item_account_assign_create.

*    TYPES: tt_purorder_create TYPE TABLE FOR CREATE i_purchaseordertp_2,
*           ty_purorder_create TYPE LINE OF tt_purorder_create.
*
*    DATA: lt_po                 TYPE tt_purorder_create,
*          lt_item               TYPE tt_purorder_items_create,
*          lt_account_assignment TYPE tt_item_account_assign_create.

    CHECK it_deep[] IS NOT INITIAL.

    DATA: lt_api_header TYPE TABLE OF ty_api_header.
    DATA: ls_return LIKE LINE OF et_return.
    DATA: ls_api_response TYPE ty_api_header, "zexed_scm_purchase_order=>tys_purchase_order_type,
          ls_remote_error TYPE ty_remote_error.

    DATA: lo_http_client  TYPE REF TO if_web_http_client,
          lo_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
          lo_request      TYPE REF TO /iwbep/if_cp_request_create,
          lo_response     TYPE REF TO /iwbep/if_cp_response_create.

    CHECK it_deep[] IS NOT INITIAL.

    TRY.
        " Create http client
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement( comm_scenario  = 'ZEXED_CS_PURCHASE_ORDER' ) .

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

        lo_http_client->get_http_request( )->set_header_fields(
          VALUE #(
            ( name = 'Accept-Language' value = 'pt-BR' )
            ( name = 'sap-language'    value = 'PT'    )
          )
        ).

*          " Create http client
        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v4_remote_proxy(
          EXPORTING
             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                 proxy_model_id      = 'ZEXED_SCM_PURCHASE_ORDER'
                                                 proxy_model_version = '0001' )
            io_http_client             = lo_http_client
            iv_relative_service_root   = '' ).
      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        "handle exception
        ls_return-msgty = 'E'.
        ls_return-msg   = |Erro Gateway ao criar Pedido (GATEWAY): { lx_gateway->get_text( ) }|.
        APPEND ls_return TO et_return.
        RETURN.
    ENDTRY.

    ASSERT lo_http_client IS BOUND.
    "process data
    LOOP AT it_deep ASSIGNING FIELD-SYMBOL(<fs_header>).
      "set row reference in return
      ls_return-row_index = sy-tabix.

      TRY.
          CLEAR: ls_return-msg,
                 ls_return-msgty,
                 ls_return-new_po.

          "fill API header
          APPEND VALUE #(
              purchase_order          = ''
              company_code            = <fs_header>-CompanyCode
              purchasing_organization = <fs_header>-PurchaseOrganization
              purchase_order_type_2   = <fs_header>-PurchaseOrderType2
              purchase_order_date     = <fs_header>-PurchaseOrderDate
              purchasing_group        = <fs_header>-PurchaseGroup
              supplier                = <fs_header>-Supplier
              payment_terms           = <fs_header>-PaymentTerms
              language                = 'P'
          ) TO lt_api_header
          ASSIGNING FIELD-SYMBOL(<fs_api_header>).


          LOOP AT <fs_header>-purchase_order_item ASSIGNING FIELD-SYMBOL(<fs_item>).
            APPEND VALUE #(
              "fill API item
              purchase_order = ''
              purchase_order_item = <fs_item>-Item
              purchase_order_category          = ''                 "Sempre vazio
              document_currency                = <fs_item>-DocumentCurrency
              Material                         = <fs_item>-Material
              Plant                            = <fs_item>-Plant
*          purchase_order_quantity_un       = <fs_item>-PurchaseOrderQuantityUnit     "Unid. Medida (item)
              purchase_order_quantity_un       = COND #( WHEN <fs_item>-PurchaseOrderQuantityUnit is not initial then zexed_cl_conv_exit_cunit=>convert_output( <fs_item>-PurchaseOrderQuantityUnit ) )     "Unid. Medida (item)
              net_price_amount                 = <fs_item>-NetPriceAmount
              order_quantity                   = <fs_item>-OrderQuantity
              is_completely_delivered          = abap_false         "Sempre False
              is_finally_invoiced              = abap_false         "Sempre False
              goods_receipt_is_expected        = abap_true          "Sempre True
              invoice_is_expected              = abap_true          "Sempre True
              purchase_requisition             = <fs_item>-PurchaseRequisition
              purchase_requisition_item        = <fs_item>-PurchaseRequisitionItem
*          base_unit                        = <fs_item>-BaseUnit
              base_unit                        = COND #( WHEN <fs_item>-BaseUnit is not initial then zexed_cl_conv_exit_cunit=>convert_output( <fs_item>-BaseUnit ) )     "Unid. Medida (item)
              purchase_order_item_catego       = ''                 "Sempre vazio
              multiple_acct_assgmt_distr       = <fs_item>-MultipleAcctAssgmtDistribution
              account_assignment_categor       = <fs_item>-AccountAssignmentCategory
              tax_code                         = <fs_item>-TaxCode
            ) TO <fs_api_header>-purchase_order_item
            ASSIGNING FIELD-SYMBOL(<fs_api_item>).

            LOOP AT <fs_item>-to_account_assignment ASSIGNING FIELD-SYMBOL(<fs_acc_ass>).
              "fill API Account Assignment
              APPEND VALUE #(
                purchase_order                  = <fs_acc_ass>-PurchaseOrder
                purchase_order_item             = <fs_acc_ass>-Item
                account_assignment_number       = <fs_acc_ass>-AccountAssignmentNumber
                cost_center                     = <fs_acc_ass>-CostCenter
                project_network                 = <fs_acc_ass>-ProjectNetwork
                network_activity                = <fs_acc_ass>-NetworkActivity
                quantity                        = <fs_acc_ass>-Quantity
*            order_quantity_unit             = <fs_acc_ass>-OrderQuantityUnit
                order_quantity_unit             = COND #( WHEN <fs_acc_ass>-OrderQuantityUnit is not initial then zexed_cl_conv_exit_cunit=>convert_output( <fs_acc_ass>-OrderQuantityUnit ) )    "Unid. Medida (item)
                document_currency               = <fs_acc_ass>-DocumentCurrency
                purg_doc_net_amount             = <fs_acc_ass>-PurgDocNetAmount
                multiple_acct_assgmt_distr      = <fs_acc_ass>-MultipleAcctAssgmtDistrPercent
                glaccount                       = <fs_acc_ass>-GLAccount
               ) TO <fs_api_item>-pur_ord_account_assignment.
            ENDLOOP.
          ENDLOOP.

          "CALL API
          TRY.
              " Navigate to the resource and create a request for the create operation
              lo_request = lo_client_proxy->create_resource_for_entity_set( 'PURCHASE_ORDER' )->create_request_for_create( ).

              " Return a data description node for the deep inboud delivery
              DATA(lo_data_desc_node_so) = lo_request->create_data_descripton_node( ).
*    " Set the properties of the Header node
              lo_data_desc_node_so->set_properties(
                VALUE #(
                  ( |PURCHASE_ORDER| )
                  ( |COMPANY_CODE| )
                  ( |PURCHASING_ORGANIZATION| )
                  ( |PURCHASE_ORDER_TYPE_2| )
                  ( |PURCHASE_ORDER_DATE| )
                  ( |PURCHASING_GROUP| )
                  ( |SUPPLIER| )
                  ( |PAYMENT_TERMS| )
                  ( |LANGUAGE| )
                )
              ).
              " Add a child node Item for a navigation property
              DATA(lo_data_desc_node_so_item) = lo_data_desc_node_so->add_child( 'PURCHASE_ORDER_ITEM' ).
              " Set the properties of the Item node
              lo_data_desc_node_so_item->set_properties(
                VALUE #(
                  ( |PURCHASE_ORDER| )
                  ( |PURCHASE_ORDER_ITEM| )
                  ( |PURCHASE_ORDER_CATEGORY| )
                  ( |DOCUMENT_CURRENCY| )
                  ( |MATERIAL| )
                  ( |PLANT| )
                  ( |PURCHASE_ORDER_QUANTITY_UN| )
                  ( |NET_PRICE_AMOUNT| )
                  ( |ORDER_QUANTITY| )
                  ( |IS_COMPLETELY_DELIVERED| )
                  ( |IS_FINALLY_INVOICED| )
                  ( |GOODS_RECEIPT_IS_EXPECTED| )
                  ( |INVOICE_IS_EXPECTED| )
                  ( |PURCHASE_REQUISITION| )
                  ( |PURCHASE_REQUISITION_ITEM| )
                  ( |BASE_UNIT| )
                  ( |PURCHASE_ORDER_ITEM_CATEGO| )
                  ( |MULTIPLE_ACCT_ASSGMT_DISTR| )
                  ( |ACCOUNT_ASSIGNMENT_CATEGOR| )
                  ( |TAX_CODE| )
                )
              ).

              " Add a child node Acc Ass for a navigation property
              DATA(lo_data_desc_node_acc_ass) = lo_data_desc_node_so_item->add_child( 'PUR_ORD_ACCOUNT_ASSIGNMENT' ).
              " Set the properties of the Acc ASs node
              lo_data_desc_node_acc_ass->set_properties(
                VALUE #(
                    ( |PURCHASE_ORDER| )
                    ( |PURCHASE_ORDER_ITEM| )
                    ( |ACCOUNT_ASSIGNMENT_NUMBER| )
                    ( |COST_CENTER| )
                    ( |PROJECT_NETWORK| )
                    ( |NETWORK_ACTIVITY| )
                    ( |QUANTITY| )
                    ( |ORDER_QUANTITY_UNIT| )
                    ( |DOCUMENT_CURRENCY| )
                    ( |PURG_DOC_NET_AMOUNT| )
                    ( |MULTIPLE_ACCT_ASSGMT_DISTR| )
                    ( |GLACCOUNT| )
                )
              ).

              lo_request->set_deep_business_data( is_business_data    = <fs_api_header>
                                                  io_data_description = lo_data_desc_node_so ).

              " Execute the request
              lo_response = lo_request->execute( ).

              CLEAR ls_api_response.
              lo_response->get_business_data(
                IMPORTING
                    es_business_data = ls_api_response
              ).

              IF ls_api_response-purchase_order IS NOT INITIAL.
                ls_return-msgty = 'S'.
                ls_return-msg   = |Pedido de Compra  { ls_api_response-purchase_order } criado com sucesso!|.
                ls_return-new_po = ls_api_response-purchase_order.
              ELSE.
                ls_return-msgty = 'E'.
                ls_return-msg   = |Erro ao publicar pedido|.
              ENDIF.

              APPEND ls_return TO et_return.

            CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
              "handle exception
              ls_return-msgty = 'E'.
              ls_return-msg   = |Erro remoto ao criar Pedido (CP_REMOTE): { lx_remote->get_text( ) }|.
              APPEND ls_return TO et_return.

              IF lx_remote->http_error_body IS NOT INITIAL.
                /ui2/cl_json=>deserialize(
                    EXPORTING
                        json = lx_remote->http_error_body
                        pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                    CHANGING
                        data = ls_remote_error
                ).

                IF ls_remote_error IS NOT INITIAL.
                  ls_return-msgty = 'E'.
                  ls_return-msg   = ls_remote_error-error-message.
                  APPEND ls_return TO et_return.

                  LOOP AT ls_remote_error-error-details ASSIGNING FIELD-SYMBOL(<fs_details>).
                    ls_return-msgty = 'E'.
                    ls_return-msg   = <fs_details>-message.
                    APPEND ls_return TO et_return.
                  ENDLOOP.
                ENDIF.
              ENDIF.


            CATCH /iwbep/cx_gateway INTO lx_gateway.
              "handle exception
              ls_return-msgty = 'E'.
              ls_return-msg   = |Erro Gateway ao criar Pedido (GATEWAY): { lx_gateway->get_text( ) }|.
              APPEND ls_return TO et_return.

          ENDTRY.

        CATCH cx_uom_error INTO DATA(lx_uom_error).
          "handle exception
          ls_return-msgty = 'E'.
          ls_return-msg   = |Erro Gateway ao converter unidade de medida|.
          APPEND ls_return TO et_return.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.