class-pool .
*"* class pool for class ZCL_TESTES_MM

*"* local type definitions
include ZCL_TESTES_MM=================ccdef.

*"* class ZCL_TESTES_MM definition
*"* public declarations
  include ZCL_TESTES_MM=================cu.
*"* protected declarations
  include ZCL_TESTES_MM=================co.
*"* private declarations
  include ZCL_TESTES_MM=================ci.
endclass. "ZCL_TESTES_MM definition

*"* macro definitions
include ZCL_TESTES_MM=================ccmac.
*"* local class implementation
include ZCL_TESTES_MM=================ccimp.

*"* test class
include ZCL_TESTES_MM=================ccau.

class ZCL_TESTES_MM implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_TESTES_MM implementation
