CLASS lhc_yeho_ddl_i_refdochd DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR yeho_ddl_i_refdochd RESULT result.

ENDCLASS.

CLASS lhc_yeho_ddl_i_refdochd IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.