  METHOD fill_json.
    TYPES : BEGIN OF ty_hesapno,
              ek_no   TYPE string,
              hes_tur TYPE string,
              ilk7    TYPE string,
            END OF ty_hesapno,
            BEGIN OF ty_input,
              baslangic_tarihi TYPE string,
              bitis_tarihi     TYPE string,
              hesap_no         TYPE ty_hesapno,
              kullanici_kodu   TYPE string,
            END OF ty_input,
            BEGIN OF ty_getaccountactivities,
              input TYPE ty_input,
            END OF ty_getaccountactivities,
            BEGIN OF ty_json,
              get_account_activities TYPE ty_getaccountactivities,
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
    ls_json-get_account_activities-input = VALUE #( baslangic_tarihi = lv_start_date
                                                    bitis_tarihi = lv_end_date
                                                    hesap_no = VALUE #( ek_no = ms_bankpass-suffix+2(1)
                                                                        hes_tur = ms_bankpass-suffix(2)
                                                                        ilk7 = ms_bankpass-bankaccount )
                                                    kullanici_kodu = ms_bankpass-bankaccount ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    REPLACE 'GetAccountActivities' in rv_json WITH 'GetAccountActivitiesWithToken'.
  ENDMETHOD.