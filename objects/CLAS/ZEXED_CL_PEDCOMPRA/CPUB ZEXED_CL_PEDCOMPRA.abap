CLASS zexed_cl_pedcompra DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:BEGIN OF ty_cria_pedido_deep_i.
            INCLUDE TYPE zexed_i_up_pdcmp_i. "item
    TYPES:  to_account_assignment TYPE TABLE OF zexed_i_up_pdcmp_a WITH EMPTY KEY,
          END OF ty_cria_pedido_deep_i.

    TYPES:BEGIN OF ty_cria_pedido_deep.
            INCLUDE TYPE zexed_i_up_pdcmp_h. "header
    TYPES:  purchase_order_item TYPE TABLE OF ty_cria_pedido_deep_i WITH EMPTY KEY,
          END OF ty_cria_pedido_deep.
    TYPES tt_cria_pedido_deep TYPE TABLE OF ty_cria_pedido_deep.

    TYPES: BEGIN OF ty_cria_pedido_return,
             row_index TYPE i,
             msgty     TYPE symsgty,
             msg       TYPE string,
             new_po    TYPE ebeln,
           END OF ty_cria_pedido_return.

    TYPES tt_cria_pedido_return TYPE STANDARD TABLE OF ty_cria_pedido_return WITH EMPTY KEY.

    TYPES: BEGIN OF ty_api_item.
             INCLUDE TYPE zexed_scm_purchase_order=>tys_purchase_order_item_type.
    TYPES:   pur_ord_account_assignment TYPE TABLE OF zexed_scm_purchase_order=>tys_purchase_order_account_a_2 WITH EMPTY KEY,
           END OF ty_api_item.

    TYPES: BEGIN OF ty_api_header.
             INCLUDE TYPE zexed_scm_purchase_order=>tys_purchase_order_type.
    TYPES:   purchase_order_item TYPE TABLE OF ty_api_item WITH EMPTY KEY,
           END OF ty_api_header.

    TYPES: BEGIN OF ty_remote_error_det,
             code    TYPE string,
             message TYPE string,
           END OF ty_remote_error_det.

    TYPES: BEGIN OF ty_remote_error_msg,
             code    TYPE string,
             message TYPE string,
             details TYPE TABLE OF ty_remote_error_det WITH EMPTY KEY,
           END OF ty_remote_error_msg.

    TYPES:BEGIN OF ty_remote_error,
            error TYPE ty_remote_error_msg,
          END OF ty_remote_error.

    CLASS-METHODS criar_pedido_deep
      IMPORTING
        it_deep   TYPE tt_cria_pedido_deep
      EXPORTING
        et_return TYPE tt_cria_pedido_return
      RAISING
        cx_web_http_client_error
        cx_http_dest_provider_error.
