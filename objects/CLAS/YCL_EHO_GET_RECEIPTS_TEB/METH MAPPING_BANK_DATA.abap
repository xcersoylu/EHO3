  METHOD mapping_bank_data.
  types:
    BEGIN OF mty_detail,
        hareket_key    TYPE string,
        islem_tar      TYPE string,
        ba             TYPE string,
        parakod        TYPE string,
        tutar          TYPE string,
        aciklama       TYPE string,
        musteri_ref    TYPE string,
        gonderen_ad    TYPE string,
        gonderen_banka TYPE string,
        gonderen_sube  TYPE string,
        islem_tar_saat TYPE string,
        anlik_bky      TYPE string,
        islem_ack      TYPE string,
        islem_tur      TYPE string,
        borclu_vkn     TYPE string,
        alacakli_vkn   TYPE string,
        gonderen_iban  TYPE string,
        dekontno       TYPE string,
        alici_iban     TYPE string,
      END OF mty_detail .
  types:
    BEGIN OF mty_hesap,
        subeno    TYPE string,
        hesno     TYPE string,
        bastar    TYPE string,
        bittar    TYPE string,
        sonbky    TYPE string,
        bloke_bky TYPE string,
        detay     TYPE TABLE OF mty_detail WITH DEFAULT KEY.
    TYPES END OF mty_hesap .
  types:
    BEGIN OF mty_result.
    TYPES hesaphareketleriresult TYPE TABLE OF mty_hesap WITH DEFAULT KEY.
    TYPES END OF mty_result .
    DATA ls_json_response TYPE mty_result.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-hesaphareketleriresult INTO DATA(ls_hesap) INDEX 1.

    LOOP AT ls_hesap-detay INTO DATA(ls_detay).
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-amount    = ls_detay-tutar.
      ls_offline_data-description = ls_detay-aciklama.

      IF ls_detay-ba EQ 'A'.
        ls_offline_data-payee_vkn = ls_detay-alacakli_vkn.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-gonderen_iban.
      ELSEIF ls_detay-ba EQ 'B'.
        ls_offline_data-debtor_vkn = ls_detay-borclu_vkn.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban      = ls_detay-alici_iban.
      ENDIF.

      ls_offline_data-additional_field1     = ls_detay-islem_ack.
      ls_offline_data-additional_field2     = ls_detay-musteri_ref.
      ls_offline_data-current_balance       = ls_detay-anlik_bky.
      ls_offline_data-receipt_no            = ls_detay-dekontno.
      ls_offline_data-physical_operation_date = ls_detay-islem_tar.
      ls_offline_data-valor                 = ls_detay-islem_tar.
      ls_offline_data-accounting_date       = ls_detay-islem_tar.
      ls_offline_data-time                  = ls_detay-islem_tar_saat.
      ls_offline_data-sender_branch         = ls_detay-gonderen_sube.
      ls_offline_data-transaction_type      = ls_detay-islem_tur.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
    IF sy-subrc IS NOT INITIAL.
*      lv_closing_balance = ls_list-acilis_bakiyesi.
    else.
      lv_closing_balance = ls_hesap-sonbky.
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
                    opening_balance =  lv_opening_balance "#TODO nasıl dolacak ?
                    closing_balance =  lv_closing_balance
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.