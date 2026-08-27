class-pool .
*"* class pool for class ZCL_PO_GROSS_TOTAL_RECONCILE

*"* local type definitions
include ZCL_PO_GROSS_TOTAL_RECONCILE==ccdef.

*"* class ZCL_PO_GROSS_TOTAL_RECONCILE definition
*"* public declarations
  include ZCL_PO_GROSS_TOTAL_RECONCILE==cu.
*"* protected declarations
  include ZCL_PO_GROSS_TOTAL_RECONCILE==co.
*"* private declarations
  include ZCL_PO_GROSS_TOTAL_RECONCILE==ci.
endclass. "ZCL_PO_GROSS_TOTAL_RECONCILE definition

*"* macro definitions
include ZCL_PO_GROSS_TOTAL_RECONCILE==ccmac.
*"* local class implementation
include ZCL_PO_GROSS_TOTAL_RECONCILE==ccimp.

*"* test class
include ZCL_PO_GROSS_TOTAL_RECONCILE==ccau.

class ZCL_PO_GROSS_TOTAL_RECONCILE implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_PO_GROSS_TOTAL_RECONCILE implementation
