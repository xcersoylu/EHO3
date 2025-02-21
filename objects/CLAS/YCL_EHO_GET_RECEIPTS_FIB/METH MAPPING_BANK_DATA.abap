  METHOD mapping_bank_data.
    TYPES:
      BEGIN OF mty_detail,
        transactiontype               TYPE string,
        currentbalance                TYPE string,
        transactionamount             TYPE string,
        iban                          TYPE string,
        accounttransactionexplanation TYPE string,
        accountingdate                TYPE string,
        transactiondate               TYPE string,
        mt940                         TYPE string,
        transactiontime               TYPE string,
        referencenumber               TYPE string,
        eftinqueryno                  TYPE string,
        currency                      TYPE string,
        identityno                    TYPE string,
        title1                        TYPE string,
        transactionno                 TYPE string,
      END OF mty_detail .
    TYPES:
      BEGIN OF mty_hesap,

        branchinfo    TYPE string,
        usablebalance TYPE string,
        startbalance  TYPE string,
        endbalance    TYPE string,
        errorcode     TYPE string,
        errortext     TYPE string,
        balance       TYPE string,
        blockbalance  TYPE string,
        detay         TYPE TABLE OF mty_detail WITH DEFAULT KEY.
    TYPES END OF mty_hesap .
    TYPES:
      BEGIN OF mty_result.
    TYPES hesaphareketleriresult TYPE TABLE OF mty_hesap WITH DEFAULT KEY.
    TYPES END OF mty_result .
    DATA ls_json_response   TYPE mty_result.
    DATA lv_sequence_no     TYPE int4.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-hesaphareketleriresult INTO DATA(ls_hesap) INDEX 1.

    lv_opening_balance = ls_hesap-startbalance.
    lv_closing_balance = ls_hesap-endbalance.

*    SPLIT ls_hesap-branchinfo AT space INTO TABLE data(lt_sube_str).
*    data(lv_lncnt) = lines( lt_sube_str ).
*
*    LOOP AT lt_sube_str INTO DATA(ls_sube_str).
*      IF sy-tabix < lv_lncnt.
*        CONCATENATE ls_list-sube_adi ls_sube_str INTO ls_list-sube_adi SEPARATED BY space.
*      ELSE.
*        ls_list-sube_kodu = ls_sube_str.
*      ENDIF.
*    ENDLOOP.

    LOOP AT ls_hesap-detay INTO DATA(ls_detay).
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-amount    = ls_detay-transactionamount.
      ls_offline_data-description = ls_detay-accounttransactionexplanation.

      IF ls_detay-transactiontype EQ 'alacak'.
        ls_offline_data-payee_vkn = ls_detay-identityno.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-iban.
      ELSEIF ls_detay-transactiontype EQ 'borc'.
        ls_offline_data-debtor_vkn = ls_detay-identityno.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban      = ls_detay-iban.
      ENDIF.

      ls_offline_data-additional_field1       = ls_detay-title1.
      ls_offline_data-additional_field2       = ls_detay-referencenumber.
      ls_offline_data-current_balance         = ls_detay-currentbalance.
      ls_offline_data-receipt_no              = ls_detay-transactionno.
      ls_offline_data-physical_operation_date = ls_detay-accountingdate.
      ls_offline_data-valor                   = ls_detay-accountingdate.
      ls_offline_data-accounting_date         = ls_detay-transactiondate.
      ls_offline_data-time                    = ls_detay-transactiontime.
      ls_offline_data-transaction_type        = ls_detay-mt940.

      APPEND ls_offline_data TO et_bank_data.

    ENDLOOP.

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