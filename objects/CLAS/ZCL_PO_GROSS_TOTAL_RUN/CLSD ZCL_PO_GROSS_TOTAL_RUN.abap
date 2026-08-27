class-pool .
*"* class pool for class ZCL_PO_GROSS_TOTAL_RUN

*"* local type definitions
include ZCL_PO_GROSS_TOTAL_RUN========ccdef.

*"* class ZCL_PO_GROSS_TOTAL_RUN definition
*"* public declarations
  include ZCL_PO_GROSS_TOTAL_RUN========cu.
*"* protected declarations
  include ZCL_PO_GROSS_TOTAL_RUN========co.
*"* private declarations
  include ZCL_PO_GROSS_TOTAL_RUN========ci.
endclass. "ZCL_PO_GROSS_TOTAL_RUN definition

*"* macro definitions
include ZCL_PO_GROSS_TOTAL_RUN========ccmac.
*"* local class implementation
include ZCL_PO_GROSS_TOTAL_RUN========ccimp.

*"* test class
include ZCL_PO_GROSS_TOTAL_RUN========ccau.

class ZCL_PO_GROSS_TOTAL_RUN implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_PO_GROSS_TOTAL_RUN implementation
