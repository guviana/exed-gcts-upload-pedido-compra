  METHOD apply_updates.
*  METHOD apply_updates.
*
*    DATA lt_entity TYPE TABLE FOR UPDATE i_purchaseordertp_2.
*
*    LOOP AT it_update INTO DATA(ls_update).
*      APPEND VALUE #(
*        purchaseorder       = ls_update-purchase_order
*        yy1_bruto_total_pdh = ls_update-gross_total
*        %control-yy1_bruto_total_pdh = if_abap_behv=>mk-on ) TO lt_entity.
*    ENDLOOP.
*
*    MODIFY ENTITIES OF i_purchaseordertp_2
*      ENTITY purchaseorder
*      UPDATE FIELDS ( yy1_bruto_total_pdh )
*      WITH lt_entity
*      FAILED   DATA(lt_failed)
*      REPORTED DATA(lt_reported).
*
*    COMMIT ENTITIES
*      RESPONSE OF i_purchaseordertp_2
*      FAILED   DATA(lt_commit_failed)
*      REPORTED DATA(lt_commit_reported).
*
*    " IMPORTANTE: registrar lt_failed / lt_commit_failed no Application Log.
*    " Uma falha em um pedido NÃO pode abortar a execução inteira.
*
*  ENDMETHOD.

    DATA lv_updated TYPE i.
    DATA lv_failed  TYPE i.

    LOOP AT it_update INTO DATA(ls_update).

      " a BO de PO aceita UM pedido por request (msg 052)
      MODIFY ENTITIES OF i_purchaseordertp_2
        ENTITY purchaseorder
        UPDATE FIELDS ( yy1_bruto_total_pdh yy1_job_bruto_proc_pdh )
        WITH VALUE #( ( purchaseorder       = ls_update-purchase_order
                        yy1_bruto_total_pdh = ls_update-gross_total
                        yy1_job_bruto_proc_pdh = 'X' ) )
        FAILED   DATA(ls_failed)
        REPORTED DATA(ls_reported).

      IF ls_failed IS NOT INITIAL.
        lv_failed += 1.
        " logar ls_update-purchase_order + ls_reported
        ROLLBACK ENTITIES.            " limpa o buffer antes do próximo pedido
        CONTINUE.                     " NÃO aborta a execução inteira
      ENDIF.

      COMMIT ENTITIES
        RESPONSE OF i_purchaseordertp_2
        FAILED   DATA(ls_commit_failed)
        REPORTED DATA(ls_commit_reported).

      IF ls_commit_failed IS NOT INITIAL.
        lv_failed += 1.
        " logar ls_update-purchase_order + ls_commit_reported
      ELSE.
        lv_updated += 1.
      ENDIF.

    ENDLOOP.

    " logar contadores: avaliados / atualizados / falharam
    " lines( it_update ) / lv_updated / lv_failed

  ENDMETHOD.