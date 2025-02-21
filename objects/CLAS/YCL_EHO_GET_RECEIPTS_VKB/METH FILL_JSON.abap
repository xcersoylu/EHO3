  METHOD fill_json.
    TYPES : BEGIN OF ty_sorgu,
              musteri_no             TYPE string,
              kurum_kullanici        TYPE string,
              sifre                  TYPE string,
              sorgu_baslangic_tarihi TYPE string,
              sorgu_bitis_tarihi     TYPE string,
              hesap_no               TYPE string,
              hareket_tipi           TYPE string,
              en_dusuk_tutar         TYPE string,
              en_yuksek_tutar        TYPE string,
            END OF ty_sorgu,
            BEGIN OF ty_getir_hareket,
              sorgu TYPE ty_sorgu,
            END OF ty_getir_hareket,
            BEGIN OF ty_json,
              getir_hareket TYPE ty_getir_hareket,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                INTO lv_end_date.

    CONCATENATE lv_start_date '00:00' INTO lv_start_date SEPARATED BY space.
    CONCATENATE lv_end_date   '23:59' INTO lv_end_date SEPARATED BY space.

    ls_json-getir_hareket-sorgu = VALUE #( musteri_no               = ms_bankpass-firm_code
                                           kurum_kullanici          = ms_bankpass-service_user
                                           sifre                    = ms_bankpass-service_password
                                           sorgu_baslangic_tarihi   = lv_start_date
                                           sorgu_bitis_tarihi       = lv_end_date
                                           hesap_no                 = ms_bankpass-bankaccount ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.