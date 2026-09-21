CLASS zcl_po_gross_total_recon_sgl DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.    " design time: job parameters
    INTERFACES if_apj_rt_exec_object.    " runtime: execute

    TYPES: BEGIN OF ty_update,
             purchase_order   TYPE i_purchaseorderapi01-purchaseorder,
             gross_total      TYPE i_purchaseorderitemapi01-netamount,
             documentcurrency TYPE i_purchaseorderapi01-documentcurrency,
           END OF ty_update.
    TYPES tt_update TYPE STANDARD TABLE OF ty_update WITH EMPTY KEY.

    METHODS collect_drifting_orders
      IMPORTING iv_purchase_order TYPE i_purchaseorderapi01-purchaseorder
      RETURNING VALUE(rt_update)  TYPE tt_update.

    METHODS apply_updates
      IMPORTING it_update TYPE tt_update.
