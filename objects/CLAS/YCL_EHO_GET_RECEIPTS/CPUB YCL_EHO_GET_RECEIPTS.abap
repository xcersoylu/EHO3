CLASS ycl_eho_get_receipts DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS factory IMPORTING is_bankpass      TYPE yeho_t_bankpass
                                    iv_startdate     TYPE datum
                                    iv_enddate       TYPE datum
                          RETURNING VALUE(ro_object) TYPE REF TO ycl_eho_get_receipts.
    METHODS call_api EXPORTING et_bank_data      TYPE yeho_tt_offline_bank_data
                               et_bank_balance   TYPE yeho_tt_offlinebd
                               ev_original_data  TYPE string
                               et_error_messages TYPE yeho_tt_message.