  METHOD set_miro_header_text.

    TYPES: BEGIN OF ty_patch,
             yy1_sgtxt_pdh TYPE string,
           END OF ty_patch.

    DATA ls_remote_error TYPE ty_remote_error.

    TRY.
        DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( io_destination ).
        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( |/PurchaseOrder('{ iv_purchase_order }')| ).
        lo_request->set_header_fields( VALUE #(
          ( name = 'Content-Type' value = 'application/json' )
          ( name = 'Accept'       value = 'application/json' )
          ( name = 'If-Match'     value = '*' )
        ) ).
        lo_request->set_text( /ui2/cl_json=>serialize( data = VALUE ty_patch( yy1_sgtxt_pdh = iv_text ) ) ).
        lo_client->set_csrf_token( ).

        DATA(lo_response) = lo_client->execute( if_web_http_client=>patch ).
        DATA(ls_status) = lo_response->get_status( ).

        IF ls_status-code < 200 OR ls_status-code >= 300.
          /ui2/cl_json=>deserialize( EXPORTING json        = lo_response->get_text( )
                                               pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                                     CHANGING  data        = ls_remote_error ).
          rv_error = COND #( WHEN ls_remote_error-error-message IS NOT INITIAL
                             THEN ls_remote_error-error-message
                             ELSE |HTTP { ls_status-code } { ls_status-reason }| ).
        ENDIF.

        lo_client->close( ).

      CATCH cx_web_http_client_error cx_web_message_error INTO DATA(lx_error).
        rv_error = lx_error->get_text( ).
    ENDTRY.

  ENDMETHOD.