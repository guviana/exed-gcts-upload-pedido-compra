  METHOD collect_drifting_orders.

*    " ---------- SELECT direto pelo número do pedido
*    "    header + agregação dos itens, sem janela de tempo
*    SELECT item~purchaseorder                                       AS purchase_order,
*           hdr~yy1_bruto_total_pdh                                  AS stored_total,
*           hdr~documentcurrency                                     AS documentcurrency,
*           hdr~yy1_bruto_total_pdhc                                 AS stored_currency,
*           SUM( CASE item~producttype
*                  WHEN '1' THEN item~effectiveamount + item~nondeductibleinputtaxamount     "material
*                  WHEN '2' THEN item~effectiveamount                                        "servico
*                  ELSE          item~netamount + item~nondeductibleinputtaxamount           "outros
*                END ) AS computed_total
*      FROM i_purchaseorderitemapi01 AS item
*           INNER JOIN i_purchaseorderapi01 AS hdr
*             ON hdr~purchaseorder = item~purchaseorder
*      WHERE item~purchaseorder                 = @iv_purchase_order
*        AND item~purchasingdocumentdeletioncode = ''
**        AND hdr~yy1_job_bruto_proc_pdh          = ''   " ver nota abaixo
*      GROUP BY item~purchaseorder,
*               hdr~yy1_bruto_total_pdh,
*               hdr~documentcurrency,
*               hdr~yy1_bruto_total_pdhc
*      INTO TABLE @DATA(lt_check).
    " PIS/COFINS 9,25% -> NETAMOUNT / ( 1 - 0,0925 )
    CONSTANTS lc_pis_cofins_rate TYPE p LENGTH 3 DECIMALS 4 VALUE '0.0925'.
    CONSTANTS lc_company_1200    TYPE bukrs VALUE '1200'.

    DATA lv_gross_up_divisor TYPE p LENGTH 3 DECIMALS 4.
    lv_gross_up_divisor = 1 - lc_pis_cofins_rate.            " 0,9075

    SELECT item~purchaseorder                                       AS purchase_order,
           hdr~yy1_bruto_total_pdh                                  AS stored_total,
           hdr~documentcurrency                                     AS documentcurrency,
           hdr~yy1_bruto_total_pdhc                                 AS stored_currency,
           SUM( CASE item~producttype

                  WHEN '1' THEN                                                   "material
                    CASE
                      WHEN hdr~companycode = @lc_company_1200
                       AND ( item~br_materialusage = '3'
                          OR item~br_materialusage = '4' )
                      THEN item~nondeductibleinputtaxamount
                           + division( item~netamount, @lv_gross_up_divisor, 2 )
                           + ( item~effectiveamount - item~netamount )
                      ELSE item~nondeductibleinputtaxamount + item~effectiveamount
                    END

*                  WHEN '2' THEN item~effectiveamount                               "servico
                  WHEN '2' THEN
                    CASE
                     WHEN item~TaxCode EQ '40' THEN
                        item~nondeductibleinputtaxamount + item~effectiveamount
                    ELSE
                        item~effectiveamount
                    END

                  ELSE          item~netamount + item~nondeductibleinputtaxamount  "outros

                END ) AS computed_total
      FROM i_purchaseorderitemapi01 AS item
           INNER JOIN i_purchaseorderapi01 AS hdr
             ON hdr~purchaseorder = item~purchaseorder
      WHERE item~purchaseorder                 = @iv_purchase_order
        AND item~purchasingdocumentdeletioncode = ''
*        AND hdr~yy1_job_bruto_proc_pdh          = ''   " ver nota abaixo
      GROUP BY item~purchaseorder,
               hdr~yy1_bruto_total_pdh,
               hdr~documentcurrency,
               hdr~yy1_bruto_total_pdhc
      INTO TABLE @DATA(lt_check).
    " ---------- só os divergentes além da tolerância
    LOOP AT lt_check INTO DATA(ls_check).

*      IF abs( ls_check-computed_total - ls_check-stored_total ) <= c_tolerance.
*        CONTINUE.                              " já correto - não tocar
*      ENDIF.

      IF ls_check-stored_total <> ls_check-computed_total
        OR ls_check-stored_currency IS INITIAL
        OR iv_bypass_check = 'X'.

        APPEND VALUE #( purchase_order      = ls_check-purchase_order
                        gross_total         = ls_check-computed_total
                        documentcurrency    = ls_check-documentcurrency ) TO rt_update.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.