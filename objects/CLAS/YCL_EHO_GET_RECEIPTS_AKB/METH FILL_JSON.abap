  METHOD fill_json.
    TYPES : BEGIN OF ty_getextrewithparams,
              urf              TYPE string,
              hesap_no         TYPE string,
              doviz_kodu       TYPE string,
              sube_kodu        TYPE string,
              baslangic_tarihi TYPE string,
              bitis_tarihi     TYPE string,
            END OF ty_getextrewithparams,
            BEGIN OF ty_json,
              get_extre_with_params TYPE ty_getextrewithparams,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    DATA lv_doviz_kodu TYPE string.
    lv_start_date = mv_startdate && '000000000000'.
    lv_end_date = mv_enddate && '235959000000'.
    ls_json-get_extre_with_params = VALUE #( hesap_no = ms_bankpass-bankaccount
                                             doviz_kodu = lv_doviz_kodu
                                             sube_kodu = ms_bankpass-branch_code
                                             baslangic_tarihi = lv_start_date
                                             bitis_tarihi = lv_end_date ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.