  METHOD collect_drifting_orders.

    " ---------- SELECT direto pelo número do pedido
    "    header + agregação dos itens, sem janela de tempo
    SELECT item~purchaseorder                                       AS purchase_order,
           hdr~yy1_bruto_total_pdh                                  AS stored_total,
           SUM( item~netamount + item~nondeductibleinputtaxamount ) AS computed_total
      FROM i_purchaseorderitemapi01 AS item
           INNER JOIN i_purchaseorderapi01 AS hdr
             ON hdr~purchaseorder = item~purchaseorder
      WHERE item~purchaseorder                 = @iv_purchase_order
*        AND item~purchasingdocumentdeletioncode = ''
*        AND hdr~yy1_job_bruto_proc_pdh          = ''   " ver nota abaixo
      GROUP BY item~purchaseorder,
               hdr~yy1_bruto_total_pdh
      INTO TABLE @DATA(lt_check).

    " ---------- só os divergentes além da tolerância
    LOOP AT lt_check INTO DATA(ls_check).

*      IF abs( ls_check-computed_total - ls_check-stored_total ) <= c_tolerance.
*        CONTINUE.                              " já correto - não tocar
*      ENDIF.

      IF ls_check-stored_total <> ls_check-computed_total.
        APPEND VALUE #( purchase_order = ls_check-purchase_order
                        gross_total    = ls_check-computed_total ) TO rt_update.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.