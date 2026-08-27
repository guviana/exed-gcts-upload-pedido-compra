  METHOD if_apj_rt_exec_object~execute.

    DATA(lv_hours) = c_default_hours.

    LOOP AT it_parameters INTO DATA(ls_param) WHERE selname = c_param_hours.
      lv_hours = CONV i( ls_param-low ).
    ENDLOOP.

    DATA(lt_update) = collect_drifting_orders( iv_hours_back = lv_hours ).

    IF lt_update IS NOT INITIAL.
      apply_updates( it_update = lt_update ).
    ENDIF.

  ENDMETHOD.