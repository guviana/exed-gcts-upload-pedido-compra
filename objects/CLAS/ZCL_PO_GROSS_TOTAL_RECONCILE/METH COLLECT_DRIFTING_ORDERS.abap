    METHOD collect_drifting_orders.

    " ---------- 1) janela de tempo
    GET TIME STAMP FIELD DATA(lv_now).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    DATA(lv_changed_since) = cl_abap_tstmp=>subtractsecs(
                               tstmp = lv_now
                               secs  = iv_hours_back * 3600 ).

    " ---------- 2) UM único SELECT: header + agregação dos itens
    "    sem FOR ALL ENTRIES (incompatível com GROUP BY)
    SELECT item~purchaseorder                                       AS purchase_order,
           hdr~yy1_bruto_total_pdh                                  AS stored_total,
           SUM( item~netamount + item~nondeductibleinputtaxamount ) AS computed_total
      FROM i_purchaseorderitemapi01 AS item
           INNER JOIN i_purchaseorderapi01 AS hdr
             ON hdr~purchaseorder = item~purchaseorder
      WHERE hdr~creationdate                    = @lv_today
        and hdr~lastchangedatetime              >= @lv_changed_since
        and hdr~yy1_job_bruto_proc_pdh           = ''
        AND item~purchasingdocumentdeletioncode  = ''
      GROUP BY item~purchaseorder,
               hdr~yy1_bruto_total_pdh
      INTO TABLE @DATA(lt_check).

    " ---------- 3) só os divergentes além da tolerância
    LOOP AT lt_check INTO DATA(ls_check).

*      IF abs( ls_check-computed_total - ls_check-stored_total ) <= c_tolerance.
*        CONTINUE.                              " já correto - não tocar
*      ENDIF.

      APPEND VALUE #( purchase_order = ls_check-purchase_order
                      gross_total    = ls_check-computed_total ) TO rt_update.

    ENDLOOP.

  ENDMETHOD.