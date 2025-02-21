  METHOD fill_json.
    TYPES : BEGIN OF ty_transactioninfoinputtype,
              account_no TYPE string,
              end_date   TYPE string,
              iban       TYPE string,
              start_date TYPE string,
            END OF ty_transactioninfoinputtype,
            BEGIN OF ty_transaction_info,
              password                    TYPE string,
              transaction_info_input_type TYPE ty_transactioninfoinputtype,
            END OF ty_transaction_info,
            BEGIN OF ty_get_transaction_info,
              transaction_info TYPE ty_transaction_info,
              user_name        TYPE string,
            END OF ty_get_transaction_info,
            BEGIN OF ty_json,
              get_transaction_info TYPE ty_get_transaction_info,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                'T'
                '00:00:00'
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                'T'
                '23:59:59'
                INTO lv_end_date.

    ls_json-get_transaction_info = VALUE #( transaction_info = VALUE #( password = ms_bankpass-service_password
                                                                        transaction_info_input_type = VALUE #(
                                                                                                            account_no = ''
                                                                                                            iban = ms_bankpass-iban
                                                                                                            start_date = lv_start_date
                                                                                                            end_date = lv_end_date ) )
                                            user_name = ms_bankpass-service_user
                                          ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.