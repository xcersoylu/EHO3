  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareket,
              referansno     TYPE string,
              saat           TYPE string,
              dekontno       TYPE string,
              tarih          TYPE string,
              aciklamalar    TYPE string,
              harekettutari  TYPE string,
              sonbakiye      TYPE string,
              ekbilgi3       TYPE string,
              ekbilgi4       TYPE string,
              musterino      TYPE string,
              islemkodu      TYPE string,
              ekbilgi1       TYPE string,
              ekbilgi2       TYPE string,
              sirano         TYPE string,
              karsihesapvkno TYPE string,
            END OF ty_hareket,
            BEGIN OF ty_hareketler,
              hareket TYPE ty_hareket,
            END OF ty_hareketler,
            tt_hareketler TYPE TABLE OF ty_hareketler WITH EMPTY KEY,
            BEGIN OF ty_tanimlamalar,
              subeadi                     TYPE string,
              acilistarihi                TYPE string,
              bakiye                      TYPE string,
              kredilikullanilabilirbakiye TYPE string,
              hesapcinsi                  TYPE string,
              kredilimiti                 TYPE string,
              hesapturu                   TYPE string,
              hesapadi                    TYPE string,
              hesapnumarasi               TYPE string,
              blokemeblag                 TYPE string,
              musterino                   TYPE string,
              karorani                    TYPE string,
              subenumarasi                TYPE string,
              vadetarihi                  TYPE string,
              sonharekettarihi            TYPE string,
              kullanilabilirbakiye        TYPE string,
            END OF ty_tanimlamalar,
            BEGIN OF ty_hesap,
              tanimlamalar TYPE ty_tanimlamalar,
              hareketler   TYPE tt_hareketler,
            END OF ty_hesap.
    DATA ls_json_response TYPE ty_hesap.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    LOOP AT ls_json_response-hareketler ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.

      ls_offline_data-physical_operation_date = ls_offline_data-valor = <fs_hareket>-hareket-tarih+6(4) && <fs_hareket>-hareket-tarih+3(2) && <fs_hareket>-hareket-tarih+0(2).
      ls_offline_data-time = <fs_hareket>-hareket-saat+0(2) && <fs_hareket>-hareket-saat+3(2) && <fs_hareket>-hareket-saat+6(2).

      CHECK ls_offline_data-physical_operation_date = mv_startdate.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-description = <fs_hareket>-hareket-aciklamalar.

      IF <fs_hareket>-hareket-harekettutari LT 0.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debtor_vkn = <fs_hareket>-hareket-karsihesapvkno.
        lv_opening_balance = lv_opening_balance - <fs_hareket>-hareket-harekettutari.
      ELSE.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-payee_vkn = <fs_hareket>-hareket-karsihesapvkno.
        SHIFT <fs_hareket>-hareket-harekettutari BY 1 PLACES LEFT.
        lv_opening_balance = lv_opening_balance + <fs_hareket>-hareket-harekettutari.
      ENDIF.

      ls_offline_data-amount           = <fs_hareket>-hareket-harekettutari.
      ls_offline_data-current_balance  = <fs_hareket>-hareket-sonbakiye.
      ls_offline_data-receipt_no       = <fs_hareket>-hareket-dekontno.
      ls_offline_data-transaction_type = <fs_hareket>-hareket-islemkodu.

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
      lv_opening_balance  = lv_closing_balance = ls_json_response-tanimlamalar-bakiye.
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