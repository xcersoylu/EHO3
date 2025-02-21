  METHOD fill_json.
    TYPES  : BEGIN OF ty_request,
               encrypted_value            TYPE string,
               ext_u_name                 TYPE string,
               ext_u_password             TYPE string,
               ext_u_sessionkey           TYPE string,
               is_new_defined_transaction TYPE string,
               language_id                TYPE string,
               method_name                TYPE string,
               account_number             TYPE string,
               account_suffix             TYPE string,
               begin_date                 TYPE string,
               debit_credit_code          TYPE string,
               end_date                   TYPE TABLE OF string WITH EMPTY KEY,
               has_time_filter            TYPE string,
*               iban                       TYPE string,
*               slip_business_key          TYPE string,
*               tax_number                 TYPE string,
*               transaction_type           TYPE string,
             END OF ty_request,
             BEGIN OF ty_getcustomertransactions,
               request TYPE ty_request,
             END OF ty_getcustomertransactions,
             BEGIN OF ty_json,
               get_customer_transactions TYPE ty_getcustomertransactions,
             END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    DATA lt_end_date type table of string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                INTO lv_end_date.
    APPEND lv_end_date to lt_end_date.
    APPEND lv_end_date to lt_end_date.
    ls_json-get_customer_transactions-request = VALUE #( ext_u_name                 = ms_bankpass-service_user
                                                         ext_u_password             = ms_bankpass-service_password
                                                         is_new_defined_transaction = 'false'
                                                         language_id                = '1'
                                                         account_number             = ms_bankpass-firm_code
                                                         account_suffix             = ms_bankpass-suffix
                                                         begin_date                 = lv_start_date
                                                         debit_credit_code          = 'All'
                                                         end_date                   = lt_end_date
                                                         has_time_filter            = '0' ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.