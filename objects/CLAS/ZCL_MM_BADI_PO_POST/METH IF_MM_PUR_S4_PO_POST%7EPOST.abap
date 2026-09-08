  METHOD if_mm_pur_s4_po_post~post.
*--------------------------------------------------------------------*
* BAdI MM_PUR_S4_PO_POST
* Agenda execucao unica do job ZJT_PO_BRUTO_TOTAL para daqui a 2 min
*--------------------------------------------------------------------*

    DATA ls_start TYPE cl_apj_rt_api=>ty_start_info.
    DATA lt_param TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA lv_tsl TYPE timestampl.

* 1) Inicio = agora + 120 segundos (timestamp em UTC)
    GET TIME STAMP FIELD ls_start-timestamp.

    GET TIME STAMP FIELD lv_tsl.
    lv_tsl = cl_abap_tstmp=>add( tstmp = lv_tsl secs = 60 ).

    cl_abap_tstmp=>move(
        EXPORTING
            tstmp_src = lv_tsl
        IMPORTING
            tstmp_tgt = ls_start-timestamp
    ).

    ls_start-start_immediately = abap_false.

* 2) Parametro P_HOURS da classe (janela de look-back curta)
    lt_param = VALUE #( ( name = 'P_PO'
                          t_value = VALUE #(
                            ( sign = 'I' option = 'EQ' low = purchaseorder-purchaseorder )
                          )
                        )
                        ( name = 'P_RETRYN'
                          t_value = VALUE #(
                            ( sign = 'I' option = 'EQ' low = 3 )
                          )
                        )
                        ( name = 'P_RETRYS'
                          t_value = VALUE #(
                            ( sign = 'I' option = 'EQ' low = 60 )
                          )
                        )
                      ).

* 3) Agendamento - falha aqui NUNCA pode derrubar o save do pedido
    TRY.
        cl_apj_rt_api=>schedule_job(
          EXPORTING
            iv_job_template_name   = 'ZPO_GROSS_TOTAL_RECON_SGL_TPL'
            iv_job_text            = 'Reconcilia bruto total PO (+1 min)'
            is_start_info          = ls_start
            it_job_parameter_value = lt_param
          IMPORTING
            ev_jobname             = DATA(lv_jobname)
            ev_jobcount            = DATA(lv_jobcount) ).

      CATCH cx_root INTO DATA(lx_error).
        data(lv_error_txt) = lx_error->get_text( ).
    ENDTRY.
  ENDMETHOD.