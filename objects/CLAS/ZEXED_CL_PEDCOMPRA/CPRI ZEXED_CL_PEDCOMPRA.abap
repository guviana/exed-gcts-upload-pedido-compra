  PRIVATE SECTION.
    "! Grava o Texto Cabeç.MIRO (campo personalizado YY1_SGTXT_PDH) no pedido criado.
    "! O modelo de consumo da API não tem o campo, por isso vai num PATCH à parte.
    "! Devolve vazio se gravou, ou a mensagem de erro.
    CLASS-METHODS set_miro_header_text
      IMPORTING
        io_destination   TYPE REF TO if_http_destination
        iv_purchase_order TYPE ebeln
        iv_text           TYPE string
      RETURNING
        VALUE(rv_error)   TYPE string.