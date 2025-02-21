  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_enrichmentvalue,
              corraccountnum      TYPE string,
              corriban            TYPE string,
              corrunitnum         TYPE string,
              modulename          TYPE string,
              producttype         TYPE string,
              corrnamesurnametext TYPE string,
              namesurnametext     TYPE string,
            END OF ty_enrichmentvalue.
    TYPES : BEGIN OF ty_enrichmentinformation,
              enrichmentcode  TYPE string,
              enrichmentvalue TYPE ty_enrichmentvalue,
            END OF ty_enrichmentinformation.
    TYPES : tyt_enrichmentinformation TYPE TABLE OF ty_enrichmentinformation WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_result,
        message_text TYPE string,
        reason_code  TYPE string,
        return_code  TYPE string,
      END OF ty_result .
    TYPES:
      BEGIN OF ty_transaction,
        iban                    TYPE string,
        tckn                    TYPE string,
        vkn                     TYPE string,
        account_num             TYPE string,
        activitydate            TYPE string,
        amount                  TYPE string,
        balanceaftertransaction TYPE string,
        clasificationcode       TYPE string,
        corrcustomernum         TYPE string,
        corrtckn                TYPE string,
        corrvkn                 TYPE string,
        currencycode            TYPE string,
        customername            TYPE string,
        customernum             TYPE string,
        enrichmentinformation   TYPE tyt_enrichmentinformation,
*        corr_account_num           TYPE string,
*        corr_iban                  TYPE string,
*        corr_unit_num              TYPE string,
*        module_name                TYPE string,
*        product_type               TYPE string,
*        corr_name_surname_text     TYPE string,
*        name_surname_text          TYPE string,
        explanation             TYPE string,
        productid               TYPE string,
        transactionid           TYPE string,
        transactioninstanceid   TYPE string,
        transactionreferenceid  TYPE string,
        txncreditdebitindicator TYPE string,
        unitnum                 TYPE string,
        valuedate               TYPE string,
      END OF ty_transaction .
    TYPES:
      tt_transaction TYPE STANDARD TABLE OF ty_transaction WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_return,
        result      TYPE ty_result,
        transaction TYPE  tt_transaction,
      END OF ty_return .
    DATA ls_json_response TYPE ty_return.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_corriban TYPE string.
    DATA lv_corrunitnum TYPE string.
    DATA lv_bankinternalid TYPE bankl.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

*    lv_bankinternalid = |{ ms_bankpass-bank_code ALPHA = IN }| && '-' && |{ ms_bankpass-branch_code ALPHA = IN }|.
*
*    SELECT SINGLE bankbranch
*      FROM i_bank_2 INNER JOIN i_companycode ON i_bank_2~bankcountry EQ  i_companycode~country
*      WHERE bankinternalid EQ  @lv_bankinternalid
*        AND companycode EQ @ms_bankpass-companycode
*     INTO @DATA(lv_branch_name).


    DATA(lv_line) = lines( ls_json_response-transaction ).
    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount = ms_bankpass-glaccount
                    valid_from = mv_startdate
                    account_no = ms_bankpass-bankaccount
                    branch_no = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  COND #( WHEN lines( ls_json_response-transaction ) > 0 THEN
                                        COND #( WHEN ls_json_response-transaction[ 1 ]-txncreditdebitindicator = 'B'
                                               THEN ( ls_json_response-transaction[ 1 ]-balanceaftertransaction + ls_json_response-transaction[ 1 ]-amount )
                                               ELSE ( ls_json_response-transaction[ 1 ]-balanceaftertransaction - ls_json_response-transaction[ 1 ]-amount ) ) )
                    closing_balance =  COND #( WHEN lines( ls_json_response-transaction ) > 0
                                                             THEN ls_json_response-transaction[ lv_line ]-balanceaftertransaction   )
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

    LOOP AT ls_json_response-transaction INTO DATA(ls_transaction).
      LOOP AT ls_transaction-enrichmentinformation INTO DATA(ls_enrichmentinformation).
        IF lv_corriban IS INITIAL.
          lv_corriban = ls_enrichmentinformation-enrichmentvalue-corriban.
        ENDIF.
        IF lv_corrunitnum IS INITIAL.
          lv_corrunitnum = ls_enrichmentinformation-enrichmentvalue-corrunitnum.
        ENDIF.
        IF lv_corriban IS NOT INITIAL AND lv_corrunitnum IS NOT INITIAL.
          EXIT.
        ENDIF.
      ENDLOOP.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-receipt_no  = ls_transaction-transactioninstanceid.
      ls_offline_data-physical_operation_date = ls_transaction-transactioninstanceid(4) &&
                                                ls_transaction-transactioninstanceid+5(2) &&
                                                ls_transaction-transactioninstanceid+8(2).
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-time = ls_transaction-transactioninstanceid+11(2) &&
                             ls_transaction-transactioninstanceid+14(2) &&
                             ls_transaction-transactioninstanceid+17(2).
      ls_offline_data-valor = ls_transaction-valuedate(4) &&
                              ls_transaction-valuedate+5(2) &&
                              ls_transaction-valuedate+8(2).
      ls_offline_data-transaction_type = ls_transaction-transactionid.
*bankadaki gösterge ile ters çalışması gerekiyor denildi.
      ls_offline_data-debit_credit = COND #( WHEN ls_transaction-txncreditdebitindicator = 'A' THEN 'B'
                                             WHEN ls_transaction-txncreditdebitindicator = 'B' THEN 'A' ).
      ls_offline_data-description = ls_transaction-explanation.
      ls_offline_data-payee_vkn = ls_transaction-vkn.
      ls_offline_data-debtor_vkn  = ls_transaction-corrvkn.
      ls_offline_data-amount = CONV f( ls_transaction-amount ).
      IF ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debit_credit = ls_offline_data-debit_credit * -1.
      ENDIF.
      ls_offline_data-current_balance = CONV f( ls_transaction-balanceaftertransaction ).
      ls_offline_data-sender_iban = lv_corriban.
      ls_offline_data-sender_branch = lv_corrunitnum.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
  ENDMETHOD.