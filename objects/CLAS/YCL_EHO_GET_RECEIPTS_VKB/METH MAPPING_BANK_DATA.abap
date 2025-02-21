  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_detaylar,
              key   TYPE string,
              value TYPE string,
            END OF ty_detaylar,
            tt_detaylar TYPE TABLE OF ty_detaylar WITH EMPTY KEY,
            BEGIN OF ty_hareketler,
              islem_tarihi         TYPE string,
              islem_no             TYPE string,
              islem_adi            TYPE string,
              tutar                TYPE string,
              borcalacak           TYPE string,
              aciklama             TYPE string,
              islem_oncesi_bakiye  TYPE string,
              islem_sonrasi_bakiye TYPE string,
              islem_yeri           TYPE string,
              islem_kanal          TYPE string,
              kartno               TYPE string,
              islem_kodu           TYPE string,
              detaylar             TYPE tt_detaylar,
              islem_tarih_zamani   TYPE string,
              id                   TYPE string,
            END OF ty_hareketler,
            tt_hareketler TYPE TABLE OF ty_hareketler WITH EMPTY KEY,
            BEGIN OF ty_ekstrehesap,
              hesap_no                     TYPE string,
              musteri_no                   TYPE string,
              musteri_unvani               TYPE string,
              sube_kodu                    TYPE string,
              sube_adi                     TYPE string,
              doviz_tipi                   TYPE string,
              acilis_bakiye                TYPE string,
              cari_bakiye                  TYPE string,
              kullanilabilir_bakiye        TYPE string,
              kredili_bankomat_limiti      TYPE string,
              kredi_bakiyesi               TYPE string,
              son_hareket_tarihi           TYPE string,
              vergi_kimlik_numarasi        TYPE string,
              hareketler                   TYPE tt_hareketler,
              hesap_tipi                   TYPE string,
              vade_baslangic_tarihi        TYPE string,
              vade_bitis_tarihi            TYPE string,
              vade_sonu_beklenen_bakiye    TYPE string,
              vade_faiz_orani              TYPE string,
              vade_sonu_odenecek_brut_faiz TYPE string, "alan uzunluğu 30 karakteri geçtiği için kısaltıldı vadesonuodenecekbrutfaiztutari
              vade_sonu_odenecek_net_faiz  TYPE string, "alan uzunluğu 30 karakteri geçtiği için kısaltıldı vadesonuodeneceknetfaiztutari
              hesap_no_iban                TYPE string,
            END OF ty_ekstrehesap,
            tt_ekstrehesap TYPE TABLE OF ty_ekstrehesap WITH EMPTY KEY,
            BEGIN OF ty_getirhareket,
              banka_kodu           TYPE string,
              banka_adi            TYPE string,
              banka_vergi_dairesi  TYPE string,
              banka_vergi_numarasi TYPE string,
              islem_kodu           TYPE string,
              islem_aciklamasi     TYPE string,
              hesaplar             TYPE tt_ekstrehesap,
            END OF ty_getirhareket.
    DATA ls_json_response   TYPE ty_getirhareket.
    DATA lv_json            TYPE string.
    DATA lv_bankinternalid  TYPE bankl.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    lv_json = iv_json.
*Alan adı uzun olduğu için değiştirildi.
    REPLACE 'VadeSonuOdenecekBrutFaizTutari' IN lv_json WITH 'VadeSonuOdenecekBrutFaiz'.
    REPLACE 'VadeSonuOdenecekNetFaizTutari' IN lv_json WITH 'VadeSonuOdenecekNetFaiz'.
***
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    lv_bankinternalid = |{ ms_bankpass-bank_code ALPHA = IN }| && '-' && |{ ms_bankpass-branch_code ALPHA = IN }|.

    SELECT SINGLE bankbranch
      FROM i_bank_2 INNER JOIN i_companycode ON i_bank_2~bankcountry EQ  i_companycode~country
      WHERE bankinternalid EQ  @lv_bankinternalid
        AND companycode EQ @ms_bankpass-companycode
     INTO @DATA(lv_branch_name).
    READ TABLE ls_json_response-hesaplar INTO DATA(ls_hesap) INDEX 1.
    LOOP AT ls_hesap-hareketler ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.
      ls_offline_data-companycode =  ms_bankpass-companycode.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.

      IF <fs_hareket>-tutar < 0.
        SHIFT <fs_hareket>-tutar BY 1 PLACES LEFT.
      ENDIF.

      ls_offline_data-amount       = <fs_hareket>-tutar.
      ls_offline_data-description    = <fs_hareket>-aciklama.
      ls_offline_data-debit_credit = <fs_hareket>-borcalacak.

      READ TABLE <fs_hareket>-detaylar INTO DATA(ls_detay) WITH KEY key = 'GonderenKimlikNumarasi'.
      IF sy-subrc = 0.
        ls_offline_data-payee_vkn = ls_detay-value.
      ENDIF.

      READ TABLE <fs_hareket>-detaylar INTO ls_detay WITH KEY key = 'AliciKimlikNumarasi'.
      IF sy-subrc = 0.
        ls_offline_data-debtor_vkn = ls_detay-value.
      ENDIF.

      ls_offline_data-current_balance = <fs_hareket>-islem_sonrasi_bakiye.
      ls_offline_data-receipt_no      = <fs_hareket>-islem_no.


      CONCATENATE <fs_hareket>-islem_tarihi+0(4)
                  <fs_hareket>-islem_tarihi+5(2)
                  <fs_hareket>-islem_tarihi+8(2)
             INTO ls_offline_data-physical_operation_date.

      CONCATENATE <fs_hareket>-islem_tarihi+11(2)
                  <fs_hareket>-islem_tarihi+14(2)
                  <fs_hareket>-islem_tarihi+17(2)
             INTO ls_offline_data-time.

      CONCATENATE <fs_hareket>-islem_tarihi+11(2)
                  <fs_hareket>-islem_tarihi+14(2)
                  <fs_hareket>-islem_tarihi+17(2)
             INTO ls_offline_data-valor.

      IF <fs_hareket>-borcalacak = 'B'.
        READ TABLE <fs_hareket>-detaylar INTO ls_detay WITH KEY key = 'AliciIbanKumarasi'.
        IF sy-subrc = 0.
          ls_offline_data-sender_iban = ls_detay-value.
        ENDIF.
      ELSE.

        READ TABLE <fs_hareket>-detaylar INTO ls_detay WITH KEY key = 'GonderenIbanKumarasi'.
        IF sy-subrc = 0.
          ls_offline_data-sender_iban = ls_detay-value.
        ENDIF.
      ENDIF.

      READ TABLE <fs_hareket>-detaylar INTO ls_detay WITH KEY key = 'SwiftKodu'.
      IF sy-subrc = 0.
        ls_offline_data-transaction_type  = ls_detay-value.
      ENDIF.

      READ TABLE <fs_hareket>-detaylar INTO ls_detay WITH KEY key = 'GonderenSubeKodu'.
      IF sy-subrc = 0.
        ls_offline_data-sender_branch = ls_detay-value.
      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
    IF sy-subrc = 0.
      SORT et_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE et_bank_data INTO DATA(ls_hareket) INDEX 1.
      IF ls_hareket-debit_credit = 'B'.
        lv_opening_balance = ls_hareket-current_balance + ls_hareket-amount.
      ELSE.
        lv_opening_balance = ls_hareket-current_balance - ls_hareket-amount.
      ENDIF.
      SORT et_bank_data BY physical_operation_date time DESCENDING.
      READ TABLE et_bank_data INTO ls_hareket INDEX 1.
      IF sy-subrc = 0.
        lv_closing_balance = ls_hareket-current_balance.
      ENDIF.
    ELSE.
      lv_opening_balance         = ls_hesap-acilis_bakiye.
      lv_closing_balance        = ls_hesap-cari_bakiye.
    ENDIF.
    APPEND VALUE #( companycode             = ms_bankpass-companycode
                    glaccount               = ms_bankpass-glaccount
                    valid_from              = mv_startdate
                    account_no              = ms_bankpass-bankaccount
                    branch_no               = ms_bankpass-branch_code
                    branch_name_description = lv_bankinternalid
                    currency                = ms_bankpass-currency
                    opening_balance         = lv_opening_balance
                    closing_balance         = lv_closing_balance
                    bank_id                 =  ''
                    account_id              = ''
                    bank_code               =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.