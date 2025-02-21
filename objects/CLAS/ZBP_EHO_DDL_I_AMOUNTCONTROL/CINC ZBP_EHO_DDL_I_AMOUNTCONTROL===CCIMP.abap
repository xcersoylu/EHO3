CLASS lhc_yeho_ddl_i_amountcontrol DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR yeho_ddl_i_amountcontrol RESULT result.

ENDCLASS.

CLASS lhc_yeho_ddl_i_amountcontrol IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.