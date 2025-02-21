  METHOD fill_json.
    TYPES : BEGIN OF ty_sorgulahesaphareketzamanile,
              musteri_no       TYPE string,
              ek_no            TYPE string,
              baslangic_zamani TYPE string,
              bitis_zamani     TYPE string,
              kurum_kod        TYPE string,
              sifre            TYPE string,
              iptal_fis_getir  TYPE string,
            END OF ty_sorgulahesaphareketzamanile,
            BEGIN OF ty_json,
              sorgula_hesap_hareket_zaman TYPE ty_sorgulahesaphareketzamanile,
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
    ls_json-sorgula_hesap_hareket_zaman = VALUE #( musteri_no       =  ms_bankpass-firm_code
                                                   ek_no            = ms_bankpass-suffix
                                                   baslangic_zamani = lv_start_date
                                                   bitis_zamani     = lv_end_date
                                                   kurum_kod        = ms_bankpass-service_user
                                                   sifre            = ms_bankpass-service_password ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    REPLACE 'sorgulaHesapHareketZaman' IN rv_json WITH 'sorgulaHesapHareketZamanIle'.
  ENDMETHOD.