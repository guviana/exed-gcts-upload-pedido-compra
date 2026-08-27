  METHOD if_apj_dt_exec_object~get_parameters.

    et_parameter_def = VALUE #(
      ( selname        = c_param_hours
        kind           = if_apj_dt_exec_object=>parameter
        datatype       = 'I'
        length         = 4
        param_text     = 'Hours to look back'
        changeable_ind = abap_true ) ).

  ENDMETHOD.