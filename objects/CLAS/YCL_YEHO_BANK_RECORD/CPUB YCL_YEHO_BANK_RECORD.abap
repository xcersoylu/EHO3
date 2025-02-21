CLASS ycl_yeho_bank_record DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension .
    METHODS get_rule CHANGING ct_items TYPE yeho_tt_bank_record_items.