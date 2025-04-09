  METHOD fill_json.
    TYPES : BEGIN OF ty_json,
              consent_id     TYPE string,
              unit_num       TYPE string,
              account_num    TYPE string,
              iban           TYPE string,
              start_date     TYPE string,
              end_date       TYPE string,
              transaction_id TYPE string,
              page_index     TYPE string,
              page_size      TYPE string,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                'T'
                '00:00:01.000'
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                'T'
                '23:59:59.999'
                INTO lv_end_date.
    ls_json = VALUE #( consent_id     = ms_bankpass-service_password
                       unit_num       = ms_bankpass-branch_code
                       account_num    = ms_bankpass-bankaccount
                       iban           = ms_bankpass-iban
                       start_date     = lv_start_date
                       end_date       = lv_end_date
                       transaction_id = ''
                       page_index     = 1
                       page_size      = 100 ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    REPLACE 'iban' IN rv_json WITH 'IBAN'.
  ENDMETHOD.