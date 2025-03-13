  METHOD mapping_bank_data.
    TYPES:
      BEGIN OF mty_transaction.
    TYPES currencycode              TYPE string.
    TYPES ddfirminvoicenumber       TYPE string.
    TYPES ddfirmreferencenumber     TYPE string.
    TYPES ddreferencenumber         TYPE string.
    TYPES debitorcreditcode         TYPE string.
    TYPES eftinquirynumber          TYPE string.
    TYPES eftreturndescription      TYPE string.
    TYPES muhasebefisno             TYPE string.
    TYPES operationname             TYPE string.
    TYPES opponentaccountno         TYPE string.
    TYPES opponentbank              TYPE string.
    TYPES opponentbankcode          TYPE string.
    TYPES opponentbranch            TYPE string.
    TYPES opponentbranchcode        TYPE string.
    TYPES opponentcitycode          TYPE string.
    TYPES opponentiban              TYPE string.
    TYPES opponenttaxnopidno        TYPE string.
    TYPES processcode               TYPE string.
    TYPES productoperationrefno     TYPE string.
    TYPES reservefield1             TYPE string.
    TYPES reservefield2             TYPE string.
    TYPES reservefield3             TYPE string.
    TYPES statementtransactionorder TYPE string.
    TYPES transactionamount         TYPE string.
    TYPES transactionbalance        TYPE string.
    TYPES transactiondate           TYPE string.
    TYPES transactiondescription    TYPE string.
    TYPES transactionexchangerate   TYPE string.
    TYPES transactionid             TYPE string.
    TYPES valuedate                 TYPE string.
    TYPES vhefirmdocumentnumber     TYPE string.
    TYPES vhetrxdescription         TYPE string.

    TYPES END OF mty_transaction .
    TYPES:
      BEGIN OF mty_accountinfo.
    TYPES accountbalance                TYPE string.
    TYPES accountcurrencycode           TYPE string.
    TYPES accountno                     TYPE string.
    TYPES accounttitle                  TYPE string.
    TYPES accounttype                   TYPE string.
    TYPES branchcode                    TYPE string.
    TYPES branchname                    TYPE string.
    TYPES customerno                    TYPE string.
    TYPES iban                          TYPE string.
    TYPES lasttrxclosingbalance         TYPE string.
    TYPES lasttrxclosingprocessdate     TYPE string.
    TYPES lasttrxclosingprocesstime     TYPE string.
    TYPES lasttrxdate                   TYPE string.
    TYPES lasttrxdebitorcreditcode      TYPE string.
    TYPES openingbalance                TYPE string.
    TYPES openingbalancedate            TYPE string.
    TYPES previoustrxdebitorcreditcode  TYPE string.
    TYPES previoustrxopeningbalance     TYPE string.
    TYPES previoustrxopeningbalancedate TYPE string.
    TYPES reservefield1                 TYPE string.
    TYPES reservefield2                 TYPE string.
    TYPES reservefield3                 TYPE string.
    TYPES statementtransactionorder     TYPE string.
    TYPES transactionamount             TYPE string.
    TYPES transactionbalance            TYPE string.
    TYPES transactiondate               TYPE string.
    TYPES transactiondescription        TYPE string.
    TYPES transactionexchangerate       TYPE string.
    TYPES transactionid                 TYPE string.
    TYPES valuedate                     TYPE string.
    TYPES vhefirmdocumentnumber         TYPE string.
    TYPES vhetrxdescription             TYPE string.
    TYPES transactions                  TYPE TABLE OF mty_transaction WITH DEFAULT KEY.
    TYPES END OF mty_accountinfo .
    TYPES:
      BEGIN OF mty_accountinforeturntype.
    TYPES accountinfos TYPE mty_accountinfo.
    TYPES END OF mty_accountinforeturntype .

    TYPES : BEGIN OF mty_return,
              accountinforeturntype TYPE mty_accountinforeturntype,
              errorcode             TYPE string,
              errordescription      TYPE string,
            END OF mty_return.
    TYPES : BEGIN OF mty_gettransactioninforesponse,
              return TYPE mty_return,
            END OF mty_gettransactioninforesponse.
    TYPES : BEGIN OF mty_json,
              gettransactioninforesponse TYPE mty_gettransactioninforesponse,
            END OF mty_json.
    DATA ls_json_response TYPE mty_json.
    DATA lv_json TYPE string.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    lv_json = iv_json.
    REPLACE 'ns:getTransactionInfoResponse' IN lv_json WITH 'getTransactionInfoResponse'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).
    LOOP AT ls_json_response-gettransactioninforesponse-return-accountinforeturntype-accountinfos-transactions INTO DATA(ls_transaction).
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-companycode =  ms_bankpass-companycode.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.
      ls_offline_data-sequence_no =  lv_sequence_no.
      ls_offline_data-receipt_no  =  ls_transaction-muhasebefisno.
      IF ls_transaction-transactiondate IS NOT INITIAL.
        CONCATENATE ls_transaction-transactiondate+0(4)
                    ls_transaction-transactiondate+5(2)
                    ls_transaction-transactiondate+8(2)
                    INTO ls_offline_data-physical_operation_date.
      ENDIF.
      ls_offline_data-currency = ms_bankpass-currency.
      ls_offline_data-sender_iban = ls_transaction-opponentiban.
      ls_offline_data-sender_bank = ls_transaction-opponentbank.
      ls_offline_data-sender_branch = ls_transaction-opponentbranch.
      ls_offline_data-transaction_type = ls_transaction-processcode.
      IF ls_transaction-transactiondescription IS NOT INITIAL.
        ls_offline_data-description      = ls_transaction-transactiondescription.
      ELSEIF ls_transaction-eftreturndescription IS NOT INITIAL.
        ls_offline_data-description      =  ls_transaction-eftreturndescription.
      ELSEIF ls_transaction-vhetrxdescription IS NOT INITIAL.
        ls_offline_data-description      = ls_transaction-vhetrxdescription.
      ENDIF.
*borç alacak göstergesi bankada ters çalıştığı söylendi o yüzden alacak ise borç , borç ise alacağa çevrildi.
      ls_offline_data-debit_credit = COND #( WHEN ls_transaction-debitorcreditcode = 'A' THEN 'B'
                                             WHEN ls_transaction-debitorcreditcode = 'B' THEN 'A' ).
*alacak ise tutarın eksi atılması istendi.
      ls_offline_data-amount         = COND #( WHEN ls_offline_data-debit_credit = 'A'
                                                    THEN -1 * ls_transaction-transactionamount
                                                    ELSE ls_transaction-transactionamount ) .
      IF ls_transaction-debitorcreditcode EQ 'A'.
        ls_offline_data-payee_vkn     = ls_transaction-opponenttaxnopidno.
      ELSEIF ls_transaction-debitorcreditcode EQ 'B'.
        ls_offline_data-debtor_vkn       = ls_transaction-opponenttaxnopidno.
      ENDIF.
      ls_offline_data-additional_field1 = ls_transaction-reservefield1.
      ls_offline_data-additional_field2 = ls_transaction-reservefield2.
      ls_offline_data-additional_field3 = ls_transaction-reservefield3.
      ls_offline_data-current_balance   = ls_transaction-transactionbalance.
      IF ls_transaction-transactiondate IS NOT INITIAL.
        CONCATENATE ls_transaction-transactiondate+11(2)
                    ls_transaction-transactiondate+14(2)
                    ls_transaction-transactiondate+17(2)
                    INTO ls_offline_data-time.
      ENDIF.
      IF ls_transaction-valuedate IS NOT INITIAL.
        CONCATENATE ls_transaction-valuedate+0(4)
                    ls_transaction-valuedate+5(2)
                    ls_transaction-valuedate+8(2)
                    INTO ls_offline_data-valor.
      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
    IF sy-subrc = 0. "hareket varsa kayıt atılsın
      DATA(ls_accountinfos) = ls_json_response-gettransactioninforesponse-return-accountinforeturntype-accountinfos.
      APPEND VALUE #( companycode             = ms_bankpass-companycode
                      glaccount               = ms_bankpass-glaccount
                      valid_from              = mv_startdate
                      account_no              = ls_accountinfos-accountno
                      branch_no               = ls_accountinfos-branchcode
                      branch_name_description = ls_accountinfos-branchname
                      currency                = ls_accountinfos-accountcurrencycode
                      opening_balance         =  ls_accountinfos-openingbalance
                      closing_balance         =  ls_accountinfos-accountbalance
                      bank_id                 =  ''
                      account_id              = ''
                      bank_code               =   ms_bankpass-bank_code
      ) TO  et_bank_balance.
    ENDIF.
  ENDMETHOD.