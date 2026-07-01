  METHOD convert_output.

    SELECT SINGLE UnitOfMeasure_E
     FROM i_unitofmeasuretext
     WHERE UnitOfMeasure = @iv_input
        AND language = @iv_language
     INTO @rv_output.

    IF sy-subrc <> 0.
      "Unit & is not defined
      RAISE EXCEPTION TYPE cx_uom_error
        MESSAGE ID 'ZEXED_MM'
        TYPE 'E'
        NUMBER 001 ##NUMBER_OK
            WITH iv_input space space space.
    ENDIF.

  ENDMETHOD.