  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareket,
              tarih           TYPE string,
              saat            TYPE string,
              hareketsirano   TYPE string,
              miktar          TYPE string,
              bakiye          TYPE string,
              aciklama        TYPE string,
              karsihesapvkn   TYPE string,
              musteriaciklama TYPE string,
              lehdarhiban     TYPE string,
              borcalacak      TYPE string,
              karsisube       TYPE string,
              isl_id          TYPE string,
              islemturu       TYPE string,
            END OF ty_hareket,
            BEGIN OF ty_hareketler,
              hareket TYPE ty_hareket,
            END OF ty_hareketler,
            tt_hareketler TYPE TABLE OF ty_hareketler WITH EMPTY KEY,
            BEGIN OF ty_tanimlamalar,
              ibanno               TYPE string,
              hesapturu            TYPE string,
              hesapno              TYPE string,
              musterino            TYPE string,
              subekodu             TYPE string,
              subeadi              TYPE string,
              dovizturu            TYPE string,
              hesapacilistarihi    TYPE string,
              sonharekettarihi     TYPE string,
              bakiye               TYPE string,
              kullanilabilirbakiye TYPE string,
            END OF ty_tanimlamalar,
            BEGIN OF ty_hesap,
              tanimlamalar TYPE ty_tanimlamalar,
              hareketler   TYPE tt_hareketler,
            END OF ty_hesap,
            BEGIN OF ty_hesaplar,
              hesap TYPE ty_hesap,
            END OF ty_hesaplar,
            tt_hesaplar TYPE TABLE OF ty_hesaplar WITH EMPTY KEY,
            BEGIN OF ty_main_hesap,
              tarih    TYPE string,
              hesaplar TYPE tt_hesaplar,
            END OF ty_main_hesap.
    DATA ls_json_response TYPE ty_main_hesap.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-hesaplar INTO DATA(ls_hesap) WITH KEY hesap-tanimlamalar-ibanno  = ms_bankpass-iban.
    CHECK sy-subrc IS INITIAL.
*    ls_list-last_updated_date_time  = ls_hesap-hesap-tanimlamalar-sonharekettarihi.

    LOOP AT ls_hesap-hesap-hareketler ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.
      IF <fs_hareket>-hareket-tarih IS NOT INITIAL.
        CONCATENATE <fs_hareket>-hareket-tarih+6(4)
                    <fs_hareket>-hareket-tarih+3(2)
                    <fs_hareket>-hareket-tarih+0(2)
             INTO ls_offline_data-physical_operation_date.
      ENDIF.

      IF <fs_hareket>-hareket-hareketsirano IS NOT INITIAL.
        ls_offline_data-time = <fs_hareket>-hareket-hareketsirano+6(6).
      ENDIF.
      CHECK ls_offline_data-physical_operation_date = mv_startdate.

      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-description  = <fs_hareket>-hareket-aciklama.
      ls_offline_data-debit_credit = <fs_hareket>-hareket-borcalacak.
      IF ls_offline_data-debit_credit = 'A'.
        ls_offline_data-payee_vkn = <fs_hareket>-hareket-karsihesapvkn.
      ENDIF.
      IF ls_offline_data-debit_credit = 'B'.
        ls_offline_data-debtor_vkn = <fs_hareket>-hareket-karsihesapvkn.
        SHIFT <fs_hareket>-hareket-miktar BY 1 PLACES LEFT.
      ENDIF.

      ls_offline_data-amount                 = <fs_hareket>-hareket-miktar.
      ls_offline_data-current_balance          = <fs_hareket>-hareket-bakiye.
      IF <fs_hareket>-hareket-hareketsirano IS NOT INITIAL.
        ls_offline_data-receipt_no           = <fs_hareket>-hareket-hareketsirano+12(6).
      ENDIF.

      CONCATENATE <fs_hareket>-hareket-tarih+6(4)
                  <fs_hareket>-hareket-tarih+3(2)
                  <fs_hareket>-hareket-tarih+0(2)
           INTO ls_offline_data-valor.

      ls_offline_Data-sender_iban      = <fs_hareket>-hareket-lehdarhiban.
      ls_offline_Data-transaction_type            = <fs_hareket>-hareket-islemturu.
      ls_offline_Data-sender_branch         = <fs_hareket>-hareket-karsisube.
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
      lv_opening_balance  = lv_closing_balance = ls_hesap-hesap-tanimlamalar-bakiye.
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