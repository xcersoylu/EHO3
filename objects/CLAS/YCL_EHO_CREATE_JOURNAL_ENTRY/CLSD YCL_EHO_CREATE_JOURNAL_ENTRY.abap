class-pool .
*"* class pool for class YCL_EHO_CREATE_JOURNAL_ENTRY

*"* local type definitions
include YCL_EHO_CREATE_JOURNAL_ENTRY==ccdef.

*"* class YCL_EHO_CREATE_JOURNAL_ENTRY definition
*"* public declarations
  include YCL_EHO_CREATE_JOURNAL_ENTRY==cu.
*"* protected declarations
  include YCL_EHO_CREATE_JOURNAL_ENTRY==co.
*"* private declarations
  include YCL_EHO_CREATE_JOURNAL_ENTRY==ci.
endclass. "YCL_EHO_CREATE_JOURNAL_ENTRY definition

*"* macro definitions
include YCL_EHO_CREATE_JOURNAL_ENTRY==ccmac.
*"* local class implementation
include YCL_EHO_CREATE_JOURNAL_ENTRY==ccimp.

*"* test class
include YCL_EHO_CREATE_JOURNAL_ENTRY==ccau.

class YCL_EHO_CREATE_JOURNAL_ENTRY implementation.
*"* method's implementations
  include methods.
endclass. "YCL_EHO_CREATE_JOURNAL_ENTRY implementation
