  METHOD if_oo_adt_classrun~main.

*    DATA(lo_reconcile) = NEW zcl_po_gross_total_reconcile( ).
*
*    " breakpoint aqui funciona normalmente (F5 entra no método)
*    DATA(lt_update) = lo_reconcile->collect_drifting_orders( iv_hours_back = 4 ).
*
*    out->write( |Orders drifting: { lines( lt_update ) }| ).
*
*    LOOP AT lt_update INTO DATA(ls_update).
*      out->write( |{ ls_update-purchase_order } -> { ls_update-gross_total }| ).
*    ENDLOOP.
*
*    " NÃO chame apply_updates enquanto não validar a seleção
*
*    IF lt_update IS NOT INITIAL.
*      lo_reconcile->apply_updates( it_update = lt_update ).
*    ENDIF.
**--------------------------------------------------------------------*
** BAdI MM_PUR_S4_PO_POST
** Agenda execucao unica do job ZJT_PO_BRUTO_TOTAL para daqui a 2 min
**--------------------------------------------------------------------*
*
*  DATA ls_start TYPE cl_apj_rt_api=>ty_start_info.
*  DATA lt_param TYPE cl_apj_rt_api=>tt_job_parameter_value.
*
** 1) Inicio = agora + 120 segundos (timestamp em UTC)
*  GET TIME STAMP FIELD ls_start-timestamp.
*  ls_start-timestamp         = cl_abap_tstmp=>add( tstmp = ls_start-timestamp
*                                                   secs  = 120 ).
*  ls_start-start_immediately = abap_false.
*
** 2) Parametro P_HOURS da classe (janela de look-back curta)
*  lt_param = VALUE #( ( name = 'P_HOURS'
*                        t_value = VALUE #(
*                            ( sign = 'I' option = 'EQ' low = '1' )
*                        )
*                    ) ).
*
** 3) Agendamento - falha aqui NUNCA pode derrubar o save do pedido
*  TRY.
*      cl_apj_rt_api=>schedule_job(
*        EXPORTING
*          iv_job_template_name   = 'ZPO_GROSS_TOTAL_RECONCILE_TPL'
*          iv_job_text            = 'Reconcilia bruto total PO (+2 min)'
*          is_start_info          = ls_start
*          it_job_parameter_value = lt_param
*        IMPORTING
*          ev_jobname             = DATA(lv_jobname)
*          ev_jobcount            = DATA(lv_jobcount) ).
*
*    CATCH cx_root INTO DATA(lx_error).
*      " opcional: registrar lx_error->get_text( ) em log
*  ENDTRY.

    DATA(lo_job) = NEW zcl_po_gross_total_recon_sgl( ).

    DATA(lt_update) = lo_job->collect_drifting_orders(
                        iv_purchase_order = '4500000068' ).

    LOOP AT lt_update ASSIGNING FIELD-SYMBOL(<fs_update>).
      <fs_update>-gross_total = 0.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      lo_job->apply_updates( it_update = lt_update ).
    ENDIF.

    out->write( lt_update ).
  ENDMETHOD.