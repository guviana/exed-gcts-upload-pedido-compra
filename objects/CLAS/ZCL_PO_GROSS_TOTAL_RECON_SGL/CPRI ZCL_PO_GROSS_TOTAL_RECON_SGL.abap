  PRIVATE SECTION.

*    CONSTANTS c_tolerance TYPE p LENGTH 5 DECIMALS 2 VALUE '0.01'.
    DATA m_param_po  TYPE i_purchaseorderapi01-purchaseorder.
    DATA m_param_retry_number  TYPE i VALUE 1.
    DATA m_param_retry_in_sec  TYPE i VALUE 60.

    CONSTANTS c_param_po  TYPE string VALUE 'P_PO'.
    CONSTANTS c_param_retry_number  TYPE string VALUE 'P_RETRYN'.
    CONSTANTS c_param_retry_in_sec  TYPE string VALUE 'P_RETRYS'.