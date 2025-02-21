  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareket,
              aciklama              TYPE string,
              atm_no                TYPE string,
              bakiye                TYPE string,
              dekont_no             TYPE string,
              ek_bilgi              TYPE string,
              ekstre_aciklama       TYPE string,
              hareket_tutari        TYPE string,
              iptal                 TYPE string,
              islem_kod             TYPE string,
              islem_yapan_ad_soyad  TYPE string,
              islem_yapan_kimlik_no TYPE string,
              karsi_ad_soyad        TYPE string,
              karsi_banka_kod       TYPE string,
              karsi_hesap_iban      TYPE string,
              karsi_kimlik_no       TYPE string,
              karsi_musteri_no      TYPE string,
              karsi_sube_kod        TYPE string,
              referans_no           TYPE string,
              saat                  TYPE string,
              sirano                TYPE string,
              tarih                 TYPE string,
            END OF ty_hareket,
            tt_hareket TYPE TABLE OF ty_hareket WITH EMPTY KEY,
            BEGIN OF ty_array_hareket,
              hareket TYPE tt_hareket,
            END OF ty_array_hareket,
            BEGIN OF ty_hesap,
              bakiye                        TYPE string,
              bloke_meblag                  TYPE string,
              faiz_orani                    TYPE string,
              hareketler                    TYPE ty_array_hareket,
              hesap_acilis_tarihi           TYPE string,
              hesap_adi                     TYPE string,
              hesap_cinsi                   TYPE string,
              hesap_no                      TYPE string,
              hesap_turu                    TYPE string,
              iban_no                       TYPE string,
              kredi_limit                   TYPE string,
              kredili_kullanilabilir_bakiye TYPE string,
              kullanilabilir_bakiye         TYPE string,
              musteri_no                    TYPE string,
              son_hareket_tarihi            TYPE string,
              sube_adi                      TYPE string,
              sube_kodu                     TYPE string,
              vade_tarihi                   TYPE string,
            END OF ty_hesap,
            tt_hesap TYPE TABLE OF ty_hesap WITH EMPTY KEY,
            BEGIN OF ty_array_hesap,
              hesap TYPE tt_hesap,
            END OF ty_array_hesap,
            BEGIN OF ty_hesap_ekstre,
              hata_aciklama TYPE string,
              hata_kodu     TYPE string,
              hesaplar      TYPE ty_array_hesap,
            END OF ty_hesap_ekstre.

    DATA ls_json_response   TYPE ty_hesap_ekstre.
    DATA lv_sequence_no     TYPE int4.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-hesaplar-hesap INTO DATA(ls_hesap) WITH KEY iban_no = ms_bankpass-iban.
    IF sy-subrc = 0.
      REPLACE ',' IN ls_hesap-kullanilabilir_bakiye WITH '.'.
    ENDIF.

    LOOP AT ls_hesap-hareketler-hareket ASSIGNING FIELD-SYMBOL(<fs_hareket>) WHERE iptal NE 'E'.
      CLEAR ls_offline_data.
      REPLACE ',' IN <fs_hareket>-hareket_tutari WITH '.'.
      REPLACE ',' IN <fs_hareket>-bakiye WITH '.'.
      CONCATENATE <fs_hareket>-tarih+6(4)
                  <fs_hareket>-tarih+3(2)
                  <fs_hareket>-tarih+0(2)
             INTO ls_offline_data-physical_operation_date.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-description = <fs_hareket>-ekstre_aciklama.
      IF <fs_hareket>-hareket_tutari < 0.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-payee_vkn = <fs_hareket>-karsi_kimlik_no.
      ENDIF.
      IF <fs_hareket>-hareket_tutari > 0.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debtor_vkn = <fs_hareket>-karsi_kimlik_no.
      ENDIF.
      SHIFT <fs_hareket>-hareket_tutari BY 1 PLACES LEFT.
      ls_offline_data-current_balance    = <fs_hareket>-bakiye.
      ls_offline_data-amount             = <fs_hareket>-hareket_tutari.
      ls_offline_data-receipt_no         = <fs_hareket>-dekont_no.
      ls_offline_data-sender_name        = <fs_hareket>-karsi_ad_soyad.
      ls_offline_data-sender_bank        = <fs_hareket>-karsi_banka_kod.
      ls_offline_data-sender_iban        = <fs_hareket>-karsi_hesap_iban.
      ls_offline_data-sender_branch      = <fs_hareket>-karsi_sube_kod.
      ls_offline_data-transaction_type   = <fs_hareket>-islem_kod.
      ls_offline_data-counter_account_no = <fs_hareket>-karsi_kimlik_no.
      ls_offline_data-accounting_date    = ls_offline_data-physical_operation_date.
      CONCATENATE <fs_hareket>-saat+0(2)
                  <fs_hareket>-saat+3(2)
                  <fs_hareket>-saat+6(2)
             INTO ls_offline_data-time.
      ls_offline_data-valor = ls_offline_data-physical_operation_date.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
    IF sy-subrc = 0.
      DATA(lt_bank_data) = et_bank_data.
      SORT lt_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
      IF ls_bank_data-debit_credit = 'B'.
        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
      ELSE.
        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
      ENDIF.
      SORT lt_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
      lv_closing_balance = ls_bank_data-current_balance.
    ELSE.
      lv_opening_balance  = lv_closing_balance = ls_hesap-kullanilabilir_bakiye.
    ENDIF.

    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount   = ms_bankpass-glaccount
                    valid_from  = mv_startdate
                    account_no  = ms_bankpass-bankaccount
                    branch_no   = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  lv_opening_balance
                    closing_balance =  lv_closing_balance
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.
  ENDMETHOD.