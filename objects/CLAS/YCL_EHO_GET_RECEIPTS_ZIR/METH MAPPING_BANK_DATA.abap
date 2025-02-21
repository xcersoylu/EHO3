  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareketler,
              doviztipi      TYPE string,
              islemtarihi    TYPE string,
              tutar          TYPE string,
              borcalacak     TYPE string,
              aciklama       TYPE string,
              muhasebetarihi TYPE string,
              valortarihi    TYPE string,
              timestamp      TYPE string,
              islemaciklama  TYPE string,
              tcknvkn        TYPE string,
              adunvan        TYPE string,
              iban           TYPE string,
              muhref         TYPE string,
              programkod     TYPE string,
              dekontno       TYPE string,
              islemtipi      TYPE string,
              kayitdurumu    TYPE string,
              iptalzamani    TYPE string,
              bakiye         TYPE string,
            END OF ty_hareketler,
            BEGIN OF ty_hareketlerdetay,
              hareketlerdetay TYPE ty_hareketler,
            END OF ty_hareketlerdetay,
            tt_hareketlerdetay TYPE TABLE OF ty_hareketlerdetay WITH EMPTY KEY,
            BEGIN OF ty_hareketdetay,
              hareketdetay TYPE tt_hareketlerdetay,
            END OF ty_hareketdetay,
            BEGIN OF ty_results,
              hatakodu      TYPE string,
              hataack       TYPE string,
              subekodu      TYPE string,
              subeadi       TYPE string,
              hesapno       TYPE string,
              acilisbakiye  TYPE string,
              caribakiye    TYPE string,
              blokelibakiye TYPE string,
              hareketdetay  TYPE ty_hareketdetay,
            END OF ty_results,
            BEGIN OF ty_result_zaman,
              result TYPE ty_results,
            END OF ty_result_zaman,
            tt_result_zaman TYPE TABLE OF ty_result_zaman WITH EMPTY KEY,
            BEGIN OF ty_response,
              response TYPE tt_result_zaman,
            END OF ty_response.
    DATA ls_json_response TYPE ty_response.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-response INTO DATA(ls_response) WITH KEY result-hesapno = ms_bankpass-iban.
    CHECK sy-subrc IS INITIAL.

    LOOP AT ls_response-result-hareketdetay-hareketdetay INTO DATA(ls_hareketdetay).
      lv_sequence_no += 1.
      ls_offline_data-sequence_no      = lv_sequence_no.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.
      ls_offline_data-description     = ls_hareketdetay-hareketlerdetay-aciklama.
      ls_offline_data-amount        = ls_hareketdetay-hareketlerdetay-tutar.
      ls_offline_data-receipt_no    = ls_hareketdetay-hareketlerdetay-dekontno.
      ls_offline_data-current_balance = ls_hareketdetay-hareketlerdetay-bakiye.
      ls_offline_data-debit_credit  = ls_hareketdetay-hareketlerdetay-borcalacak.

      IF ls_hareketdetay-hareketlerdetay-borcalacak EQ 'B'.
        ls_offline_data-debtor_vkn   = ls_hareketdetay-hareketlerdetay-tcknvkn.
      ELSEIF ls_offline_data-debit_credit EQ 'A'.
        ls_offline_data-debtor_vkn = ls_hareketdetay-hareketlerdetay-tcknvkn.
      ENDIF.

      ls_offline_data-transaction_type       = ls_hareketdetay-hareketlerdetay-islemtipi.
      ls_offline_data-sender_name      = ls_hareketdetay-hareketlerdetay-adunvan.
      ls_offline_data-sender_iban = ls_hareketdetay-hareketlerdetay-iban.

      CONCATENATE ls_hareketdetay-hareketlerdetay-islemtarihi+0(4)
                  ls_hareketdetay-hareketlerdetay-islemtarihi+5(2)
                  ls_hareketdetay-hareketlerdetay-islemtarihi+8(2)
                  INTO ls_offline_data-physical_operation_date.

      CONCATENATE ls_hareketdetay-hareketlerdetay-islemtarihi+11(2)
                  ls_hareketdetay-hareketlerdetay-islemtarihi+14(2)
                  ls_hareketdetay-hareketlerdetay-islemtarihi+17(2)
             INTO ls_offline_data-time.

*      IF ls_list-last_updated_date_time LT ls_hareket-fiziksel_islem_tarihi.
*        ls_list-last_updated_date_time = ls_hareket-fiziksel_islem_tarihi.
*      ENDIF.

      APPEND ls_offline_data TO et_bank_data.
      CLEAR  ls_offline_data.
    ENDLOOP.
    IF sy-subrc = 0.
      DATA(lt_bank_data) = et_bank_data.
      SORT lt_bank_data BY physical_operation_date ASCENDING.
      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
      IF ls_bank_data-debit_credit = 'B'.
        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
      ELSE.
        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
      ENDIF.
      SORT lt_bank_data BY physical_operation_date ASCENDING.
      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
       lv_closing_balance = ls_bank_data-current_balance.
    ELSE.
      lv_opening_balance  = ls_response-result-acilisbakiye.
      lv_closing_balance = ls_response-result-caribakiye.
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