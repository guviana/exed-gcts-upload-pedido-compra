  METHOD if_oo_adt_classrun~main.

    DATA(lo_reconcile) = NEW zcl_po_gross_total_reconcile( ).

    " breakpoint aqui funciona normalmente (F5 entra no método)
    DATA(lt_update) = lo_reconcile->collect_drifting_orders( iv_hours_back = 4 ).

    out->write( |Orders drifting: { lines( lt_update ) }| ).

    LOOP AT lt_update INTO DATA(ls_update).
      out->write( |{ ls_update-purchase_order } -> { ls_update-gross_total }| ).
    ENDLOOP.

    " NÃO chame apply_updates enquanto não validar a seleção

    IF lt_update IS NOT INITIAL.
      lo_reconcile->apply_updates( it_update = lt_update ).
    ENDIF.
  ENDMETHOD.