class-pool .
*"* class pool for class YCL_EHO_RECORDING_OPEN_CLOSE

*"* local type definitions
include YCL_EHO_RECORDING_OPEN_CLOSE==ccdef.

*"* class YCL_EHO_RECORDING_OPEN_CLOSE definition
*"* public declarations
  include YCL_EHO_RECORDING_OPEN_CLOSE==cu.
*"* protected declarations
  include YCL_EHO_RECORDING_OPEN_CLOSE==co.
*"* private declarations
  include YCL_EHO_RECORDING_OPEN_CLOSE==ci.
endclass. "YCL_EHO_RECORDING_OPEN_CLOSE definition

*"* macro definitions
include YCL_EHO_RECORDING_OPEN_CLOSE==ccmac.
*"* local class implementation
include YCL_EHO_RECORDING_OPEN_CLOSE==ccimp.

*"* test class
include YCL_EHO_RECORDING_OPEN_CLOSE==ccau.

class YCL_EHO_RECORDING_OPEN_CLOSE implementation.
*"* method's implementations
  include methods.
endclass. "YCL_EHO_RECORDING_OPEN_CLOSE implementation
