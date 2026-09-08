  METHOD if_apj_rt_exec_object~execute.

    LOOP AT it_parameters INTO DATA(ls_param).
      IF ls_param-selname = c_param_po.
        m_param_po = |{ ls_param-low ALPHA = IN }|.
      ENDIF.

      IF ls_param-selname = c_param_retry_number.
        m_param_retry_number = ls_param-low.
      ENDIF.

      IF ls_param-selname = c_param_retry_in_sec.
        m_param_retry_in_sec = ls_param-low.
      ENDIF.
    ENDLOOP.

    IF m_param_po IS INITIAL.
      " sem pedido informado não há o que reconciliar
      RETURN.
    ENDIF.

    DATA(lt_update) = collect_drifting_orders( iv_purchase_order = m_param_po ).

    IF lt_update IS NOT INITIAL.
      apply_updates( it_update = lt_update ).
    ENDIF.

  ENDMETHOD.