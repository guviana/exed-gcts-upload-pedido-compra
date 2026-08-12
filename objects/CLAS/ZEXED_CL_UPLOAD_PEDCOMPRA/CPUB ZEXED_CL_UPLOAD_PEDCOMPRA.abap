CLASS zexed_cl_upload_pedcompra DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " Tipos e constantes compartilhadas
*    TYPES: BEGIN OF ty_excel,
*             purchase_order TYPE string,
*             company_code   TYPE string,
*             purchase_org   TYPE string,
*             purchase_grp   TYPE string,
*           END OF ty_excel.
*
*    TYPES gt_excel TYPE TABLE OF ty_excel.

    TYPES: BEGIN OF gty_date_conversion,
             data_formatted TYPE string,  " DD/MM/YYYY
             data_dats      TYPE datum,    " YYYYMMDD
           END OF gty_date_conversion.

*    TYPES: BEGIN OF ty_excel_po_h_custom,
*             yy_1_prazo_header_pdh      TYPE string,
*             yy_1_departamento_heade_pd TYPE string,
*             yy_1_rir_pdh               TYPE string,
*           END OF ty_excel_po_h_custom.

    TYPES: BEGIN OF ty_excel_po_h,
             purchase_order             TYPE string,
             purchase_order_type        TYPE string,
             purchase_order_date        TYPE string,
             company_code               TYPE string,
             purchase_org               TYPE string,
             purchase_grp               TYPE string,
             supplier                   TYPE string,
             payment_terms              TYPE string,
             yy_1_prazo_header_pdh      TYPE string,
             yy_1_departamento_heade_pd TYPE string,
             yy_1_rir_pdh               TYPE string,
           END OF ty_excel_po_h.
*    TYPES: include TYPE zexed_cl_upload_pedcompra=>ty_excel_po_h_custom.
*    TYPES: END OF ty_excel_po_h.


    TYPES gt_excel_po_h TYPE TABLE OF ty_excel_po_h.

    TYPES: BEGIN OF ty_excel_po_i_acc,
             purchase_order                 TYPE string,
             item                           TYPE string,
             cost_center                    TYPE string,
             wbselement_external_id         TYPE string,
             network_activity               TYPE string,   "Diagrama de Rede
             quantity                       TYPE string,   "Quantidade
             order_quantity_unit            TYPE string,   "Unidade de Medida
             document_currency              TYPE string, "Moeda
             purg_doc_net_amount            TYPE string,   "Valor
             mult_acct_assgmt_distr_percent TYPE string,  "0..100
             glaccount                      TYPE string,   "Conta contábil
             master_fixed_asset             TYPE string,
*             project_network             TYPE string,
           END OF ty_excel_po_i_acc.

    TYPES gt_excel_po_i_acc TYPE TABLE OF ty_excel_po_i_acc.

    TYPES: BEGIN OF ty_excel_po_i,
             purchase_order               TYPE string,
             item                         TYPE string,
             material                     TYPE string,
             plant                        TYPE string,
             document_currency            TYPE string,
             net_price_amount             TYPE string,
             order_quantity               TYPE string,
             purchase_order_quantity_unit TYPE string,
             purchase_requisition         TYPE string,
             purchase_requisition_item    TYPE string,
             base_unit                    TYPE string,
             mult_acct_ass_dist           TYPE string,
             account_assignment_category  TYPE string,
             tax_code                     TYPE string,
             purchase_contract            TYPE string,   "Contrato
             purchase_contract_item       TYPE string,   "Item do Contrato
             goods_receipt_is_expected    TYPE string,
             invoice_is_goods_receipt_b   TYPE string,
             to_account_assignment        TYPE STANDARD TABLE OF zexed_cl_upload_pedcompra=>ty_excel_po_i_acc WITH EMPTY KEY,
           END OF ty_excel_po_i.

    TYPES gt_excel_po_i TYPE TABLE OF ty_excel_po_i.

    TYPES: BEGIN OF ty_excel.
             INCLUDE TYPE zexed_cl_upload_pedcompra=>ty_excel_po_h.
    TYPES:   to_items TYPE STANDARD TABLE OF zexed_cl_upload_pedcompra=>ty_excel_po_i WITH EMPTY KEY,
           END OF ty_excel.

    TYPES gt_excel TYPE TABLE OF ty_excel.

    CONSTANTS: BEGIN OF c_excel_headers,
                 purchase_order             TYPE string VALUE `PEDIDO COMPRA`,
                 purchase_order_type        TYPE string VALUE `TIPO`,
                 purchase_order_date        TYPE string VALUE `DATA PED.`,
                 company_code               TYPE string VALUE `EMPRESA`,
                 purchase_org               TYPE string VALUE `ORG. COMPRA`,
                 purchase_grp               TYPE string VALUE `GRP. COMPRA`,
                 supplier                   TYPE string VALUE `FORNECEDOR`,
                 payment_terms              TYPE string VALUE `TERMO PGTO.`,
                 yy_1_prazo_header_pdh      TYPE string VALUE `PRAZO`,
                 yy_1_departamento_heade_pd TYPE string VALUE `DEPARTAMENTO`,
                 yy_1_rir_pdh               TYPE string VALUE `RIR`,
               END OF c_excel_headers,
               BEGIN OF c_excel_it_headers,
                 purchase_order               TYPE string VALUE `PEDIDO COMPRA`,
                 item                         TYPE string VALUE `ITEM`,
                 material                     TYPE string VALUE `MATERIAL`,
                 plant                        TYPE string VALUE `CENTRO`,
                 document_currency            TYPE string VALUE `MOEDA`,
                 net_price_amount             TYPE string VALUE `PRECO LIQ.`,
                 order_quantity               TYPE string VALUE `QUANTIDADE`,
                 purchase_order_quantity_unit TYPE string VALUE `UNID. QTDE.`,
                 purchase_requisition         TYPE string VALUE `REQ. COMPRA`,
                 purchase_requisition_item    TYPE string VALUE `REQ. ITEM`,
                 base_unit                    TYPE string VALUE `UNID. ITEM`,
                 mult_acct_ass_dist           TYPE string VALUE `RATEIO DE CUSTO`,
                 account_assignment_category  TYPE string VALUE `CAT. CLASS. CONT.`,
                 tax_code                     TYPE string VALUE `COD. IVA`,
                 purchase_contract            TYPE string VALUE `CONTRATO`,
                 purchase_contract_item       TYPE string VALUE `CONTRATO_ITEM`,
                 goods_receipt_is_expected    TYPE string VALUE `EM`,
                 invoice_is_goods_receipt_b   TYPE string VALUE `FatBasEM`,
               END OF c_excel_it_headers,
               BEGIN OF c_excel_acc_headers,
                 purchase_order                 TYPE string VALUE `PEDIDO COMPRA`,
                 item                           TYPE string VALUE `ITEM`,
                 cost_center                    TYPE string VALUE `CENTRO CUSTO`,
                 wbs_element                    TYPE string VALUE `ELEM. PEP`,
                 network_activity               TYPE string VALUE `DIAGRAMA DE REDE`,
                 quantity                       TYPE string VALUE `QUANTIDADE`,
                 order_quantity_unit            TYPE string VALUE `UNID. QTDE.`,
                 purg_doc_net_amount            TYPE string VALUE `VALOR`,
                 mult_acct_assgmt_distr_percent TYPE string VALUE `PERCENTUAL (0-100)`,
                 glaccount                      TYPE string VALUE `CONTA CONTÁBIL`,
                 master_fixed_asset             TYPE string VALUE `ATIVO`,
*                 project_network                TYPE string VALUE `PROJ NETWORK`,
               END OF c_excel_acc_headers.

    " Métodos estáticos
    CLASS-METHODS read_excel
      IMPORTING
        iv_file_content TYPE xstring
      EXPORTING
        et_excel_data   TYPE gt_excel
        ev_is_valid     TYPE abap_bool
      RAISING
        cx_abap_invalid_value.

    CLASS-METHODS validate_excel_headers
      IMPORTING
        it_excel           TYPE gt_excel
      RETURNING
        VALUE(rv_is_valid) TYPE abap_bool.

    CLASS-METHODS convert_excel_date
      IMPORTING
        iv_excel_date        TYPE i
      RETURNING
        VALUE(rs_conversion) TYPE gty_date_conversion.