  METHOD if_apj_dt_exec_object~get_parameters.

    et_parameter_def = VALUE #(
      ( selname        = c_param_po
        kind           = if_apj_dt_exec_object=>parameter
        datatype       = 'C'
        length         = 10
        param_text     = 'Purchase Order'
        changeable_ind = abap_true
        mandatory_ind  = abap_true )

      ( selname        = c_param_retry_number
        kind           = if_apj_dt_exec_object=>parameter
        datatype       = 'N'
        length         = 2
        param_text     = 'Max Retry Number'
        changeable_ind = abap_true
        mandatory_ind  = abap_true )

      ( selname        = c_param_retry_in_sec
        kind           = if_apj_dt_exec_object=>parameter
        datatype       = 'N'
        length         = 3
        param_text     = 'Retry Time in Seconds'
        changeable_ind = abap_true
        mandatory_ind  = abap_true )
     ).

  ENDMETHOD.