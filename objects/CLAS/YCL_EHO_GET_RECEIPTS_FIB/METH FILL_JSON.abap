  METHOD fill_json.
    TYPES : BEGIN OF ty_getstatementinfo,
              corporation_code TYPE string,
              account_no       TYPE string,
              start_date       TYPE string,
              end_date         TYPE string,
              password         TYPE string,
              summary          TYPE string,
            END OF ty_getstatementinfo,
            BEGIN OF ty_json,
              get_statement_info TYPE ty_getstatementinfo,
            END OF ty_json.
        DATA ls_json TYPE ty_json.
         ls_json-get_statement_info = VALUE #( corporation_code = ms_bankpass-firm_code
                                                account_no      = ms_bankpass-bankaccount
                                                start_date      = mv_startdate
                                                end_date        = mv_enddate
                                                password        = ms_bankpass-service_password
                                                summary         = '0' ).
rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.