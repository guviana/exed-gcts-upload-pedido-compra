class-pool .
*"* class pool for class ZCL_PO_GROSS_TOTAL_RECON_SGL

*"* local type definitions
include ZCL_PO_GROSS_TOTAL_RECON_SGL==ccdef.

*"* class ZCL_PO_GROSS_TOTAL_RECON_SGL definition
*"* public declarations
  include ZCL_PO_GROSS_TOTAL_RECON_SGL==cu.
*"* protected declarations
  include ZCL_PO_GROSS_TOTAL_RECON_SGL==co.
*"* private declarations
  include ZCL_PO_GROSS_TOTAL_RECON_SGL==ci.
endclass. "ZCL_PO_GROSS_TOTAL_RECON_SGL definition

*"* macro definitions
include ZCL_PO_GROSS_TOTAL_RECON_SGL==ccmac.
*"* local class implementation
include ZCL_PO_GROSS_TOTAL_RECON_SGL==ccimp.

*"* test class
include ZCL_PO_GROSS_TOTAL_RECON_SGL==ccau.

class ZCL_PO_GROSS_TOTAL_RECON_SGL implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_PO_GROSS_TOTAL_RECON_SGL implementation
