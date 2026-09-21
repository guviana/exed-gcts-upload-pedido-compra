  METHOD apply_updates.

    DATA lv_updated TYPE i.
    DATA lv_failed  TYPE i.

    LOOP AT it_update INTO DATA(ls_update).

      DO m_param_retry_number TIMES.
        DATA(lv_index) = sy-index.
        " a BO de PO aceita UM pedido por request (msg 052)
        MODIFY ENTITIES OF i_purchaseordertp_2
          ENTITY purchaseorder
          UPDATE FIELDS ( yy1_bruto_total_pdh yy1_bruto_total_pdhc yy1_job_bruto_proc_pdh )
          WITH VALUE #( ( purchaseorder          = ls_update-purchase_order
                          yy1_bruto_total_pdh    = ls_update-gross_total
                          yy1_bruto_total_pdhc   = ls_update-documentcurrency
                          yy1_job_bruto_proc_pdh = 'X' ) )
*                        ENTITY PurchaseOrderItem
*                        UPDATE FIELDS ( yy1 )
*                        WITH ls_update-items
          FAILED   DATA(ls_failed)
          REPORTED DATA(ls_reported).

        IF ls_failed IS NOT INITIAL.
          lv_failed += 1.
          " logar ls_update-purchase_order + ls_reported
          ROLLBACK ENTITIES.
          "verifica se o wait eh necessario ser executado para a proxima iteracao (se for o ultimo, nao fazer)
          IF m_param_retry_number > 1 AND lv_index < m_param_retry_number.
            WAIT UP TO m_param_retry_in_sec SECONDS.
            CONTINUE.
          ELSE.
            EXIT.
          ENDIF.

        ENDIF.

        COMMIT ENTITIES
          RESPONSE OF i_purchaseordertp_2
          FAILED   DATA(ls_commit_failed)
          REPORTED DATA(ls_commit_reported).

        IF ls_commit_failed IS NOT INITIAL.
          lv_failed += 1.
          " logar ls_update-purchase_order + ls_commit_reported
          "verifica se o wait eh necessario ser executado para a proxima iteracao (se for o ultimo, nao fazer)
          IF m_param_retry_number > 1 AND lv_index < m_param_retry_number.
            WAIT UP TO m_param_retry_in_sec SECONDS.
            CONTINUE.
          ENDIF.
        ELSE.
          lv_updated += 1.
          EXIT.
        ENDIF.
      ENDDO.

    ENDLOOP.

    " logar contadores: avaliados / atualizados / falharam
    " lines( it_update ) / lv_updated / lv_failed

  ENDMETHOD.