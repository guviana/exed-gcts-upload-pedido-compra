CLASS zexed_cl_conv_exit_cunit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      convert_input
        IMPORTING
                  iv_input         TYPE mseh3
                  iv_language      TYPE spras DEFAULT 'P'
        RETURNING VALUE(rv_output) TYPE msehi
        RAISING
                  cx_uom_error ,
      convert_output
        IMPORTING
                  iv_input         TYPE msehi
                  iv_language      TYPE spras DEFAULT 'P'
        RETURNING VALUE(rv_output) TYPE mseh3
        RAISING
                  cx_uom_error .