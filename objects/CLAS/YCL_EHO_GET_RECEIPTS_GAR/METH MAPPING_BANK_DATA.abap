  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_enrichmentvalue,
              corr_account_num       TYPE string,
              module_name            TYPE string,
              corr_unit_num          TYPE string,
              corr_iban              TYPE string,
              product_type           TYPE string,
              corr_name_surname_text TYPE string,
              name_surname_text      TYPE string,
            END OF ty_enrichmentvalue.
    TYPES : BEGIN OF ty_enrichmentinformation,
              enrichment_value TYPE ty_enrichmentvalue,
              enrichment_code  TYPE string,
            END OF ty_enrichmentinformation.
    TYPES : tyt_enrichmentinformation TYPE TABLE OF ty_enrichmentinformation WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_result,
        return_code  TYPE string,
        reason_code  TYPE string,
        message_text TYPE string,
      END OF ty_result .
    TYPES:
      BEGIN OF ty_transaction,
        corr_tckn                  TYPE string,
        amount                     TYPE string,
        corr_vkn                   TYPE string,
        product_id                 TYPE string,
        account_num                TYPE string,
        iban                       TYPE string,
        transaction_instance_id    TYPE string,
        clasification_code         TYPE string,
        customer_num               TYPE string,
        unit_num                   TYPE string,
        corr_account_num           TYPE string,
        module_name                TYPE string,
        corr_unit_num              TYPE string,
        corr_iban                  TYPE string,
        product_type               TYPE string,
        corr_name_surname_text     TYPE string,
        name_surname_text          TYPE string,
*        enrichment_information     TYPE tyt_enrichmentinformation,
        value_date                 TYPE string,
        explanation                TYPE string,
        balance_after_transaction  TYPE string,
        customer_name              TYPE string,
        transaction_id             TYPE string,
        transaction_reference_id   TYPE string,
        activity_date              TYPE string,
        tckn                       TYPE string,
        vkn                        TYPE string,
        currency_code              TYPE string,
        txn_credit_debit_indicator TYPE string,
        corr_customer_num          TYPE string,
      END OF ty_transaction .
    TYPES:
      tt_transaction TYPE STANDARD TABLE OF ty_transaction WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_return,
        result      TYPE ty_result,
        transaction TYPE  tt_transaction,
      END OF ty_return .
    TYPES ty_wrbtr TYPE yeho_e_wrbtr.
    DATA ls_json_response   TYPE ty_return.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_bankinternalid  TYPE bankl.
    DATA lv_sequence_no     TYPE int4.
    DATA ls_json            TYPE REF TO data.

    FIELD-SYMBOLS <enrichment_tab> TYPE ANY TABLE.
    FIELD-SYMBOLS <transactions_tab> TYPE ANY TABLE.

*    /ui2/cl_json=>deserialize( EXPORTING json = iv_json pretty_name = 'X' CHANGING data = ls_json_response ).
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json pretty_name = 'X' CHANGING data = ls_json ).
    ASSIGN  ls_json->* TO FIELD-SYMBOL(<data>).
    ASSIGN COMPONENT 'RESULT' OF STRUCTURE <data> TO FIELD-SYMBOL(<result>).
    ASSIGN <result>->* TO FIELD-SYMBOL(<result_str>).
    ASSIGN COMPONENT 'MESSAGE_TEXT' OF STRUCTURE <result_str> TO FIELD-SYMBOL(<message_text>).
    ASSIGN <message_text>->* TO FIELD-SYMBOL(<fs_val>).
    ls_json_response-result-message_text = COND #( WHEN <fs_val> IS ASSIGNED THEN  <fs_val> ).
    UNASSIGN <fs_val>.
    ASSIGN COMPONENT 'REASON_CODE' OF STRUCTURE <result_str> TO FIELD-SYMBOL(<reason_code>).
    ASSIGN <reason_code>->* TO <fs_val>.
    ls_json_response-result-reason_code = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
    UNASSIGN <fs_val>.
    ASSIGN COMPONENT 'RETURN_CODE' OF STRUCTURE <result_str> TO FIELD-SYMBOL(<return_code>).
    ASSIGN <return_code>->* TO <fs_val>.
    ls_json_response-result-return_code = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
    UNASSIGN <fs_val>.
    CHECK ls_json_response-result-return_code EQ 200.
    """""""""""""""""""""""""""""""""""""""""""""""""
    ASSIGN COMPONENT 'TRANSACTIONS' OF STRUCTURE <data> TO FIELD-SYMBOL(<transactions>).
    CHECK <transactions> IS ASSIGNED.
    ASSIGN <transactions>->* TO <transactions_tab>.
    LOOP AT  <transactions_tab> ASSIGNING FIELD-SYMBOL(<transaction>).
      ASSIGN <transaction>->* TO FIELD-SYMBOL(<transaction_str>).
      APPEND INITIAL LINE TO ls_json_response-transaction REFERENCE INTO DATA(lr_transaction).
      ASSIGN COMPONENT 'IBAN' OF STRUCTURE <transaction_str> TO FIELD-SYMBOL(<fs_field>).
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->iban = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'TCKN' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->tckn = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'VKN' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->vkn = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'ACCOUNT_NUM' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->account_num = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'ACTIVITY_DATE' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->activity_date = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'AMOUNT' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->amount = CONV ty_wrbtr( COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ) ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'BALANCE_AFTER_TRANSACTION' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->balance_after_transaction = CONV ty_wrbtr( COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ) ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CLASIFICATION_CODE' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->clasification_code = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CORR_CUSTOMER_NUM' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->corr_customer_num = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CORR_TCKN' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->corr_tckn = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CORR_VKN' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->corr_vkn = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CURRENCY_CODE' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->currency_code = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CUSTOMER_NAME' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->customer_name = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'CUSTOMER_NUM' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->customer_num = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.

      ASSIGN COMPONENT 'ENRICHMENT_INFORMATION' OF STRUCTURE <transaction_str> TO FIELD-SYMBOL(<enrichment_info>).
      ASSIGN <enrichment_info>->* TO <enrichment_tab>.
      LOOP AT  <enrichment_tab> ASSIGNING FIELD-SYMBOL(<enrichment>).
        ASSIGN <enrichment>->* TO FIELD-SYMBOL(<enrichment_str>).
        ASSIGN COMPONENT 'ENRICHMENT_VALUE' OF STRUCTURE <enrichment_str> TO FIELD-SYMBOL(<enrichment_value>).
        ASSIGN <enrichment_value>->* TO FIELD-SYMBOL(<enrichment_value_str>).
        ASSIGN COMPONENT 'CORR_ACCOUNT_NUM' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->corr_account_num = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
        ASSIGN COMPONENT 'CORR_IBAN' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->corr_iban = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
        ASSIGN COMPONENT 'CORR_UNIT_NUM' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->corr_unit_num = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
        ASSIGN COMPONENT 'MODULE_NAME' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->module_name = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
        ASSIGN COMPONENT 'PRODUCT_TYPE' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->product_type = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
        ASSIGN COMPONENT 'CORR_NAME_SURNAME_TEXT' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->corr_name_surname_text = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
        ASSIGN COMPONENT 'NAME_SURNAME_TEXT' OF STRUCTURE <enrichment_value_str> TO <fs_field>.
        IF <fs_field> IS ASSIGNED.
          ASSIGN <fs_field>->* TO <fs_val>.
        ENDIF.
        lr_transaction->name_surname_text = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
        UNASSIGN : <fs_field>, <fs_val>.
      ENDLOOP.

      ASSIGN COMPONENT 'EXPLANATION' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->explanation = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'PRODUCT_ID' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->product_id = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'TRANSACTION_ID' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->transaction_id = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'TRANSACTION_INSTANCE_ID' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->transaction_instance_id = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'TRANSACTION_REFERENCE_ID' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->transaction_reference_id = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'TXN_CREDIT_DEBIT_INDICATOR' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->txn_credit_debit_indicator = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'UNIT_NUM' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->unit_num = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
      ASSIGN COMPONENT 'VALUE_DATE' OF STRUCTURE <transaction_str> TO <fs_field>.
      IF <fs_field> IS ASSIGNED.
        ASSIGN <fs_field>->* TO <fs_val>.
      ENDIF.
      lr_transaction->value_date = COND #( WHEN <fs_val> IS ASSIGNED THEN <fs_val> ).
      UNASSIGN : <fs_field>, <fs_val>.
    ENDLOOP.

    """"""""""""""""""""""""""""""""""""""""""""""""""
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
                                        COND #( WHEN ls_json_response-transaction[ 1 ]-txn_credit_debit_indicator = 'B'
                                               THEN ( ls_json_response-transaction[ 1 ]-balance_after_transaction + ls_json_response-transaction[ 1 ]-amount )
                                               ELSE ( ls_json_response-transaction[ 1 ]-balance_after_transaction - ls_json_response-transaction[ 1 ]-amount ) ) )
                    closing_balance =  COND #( WHEN lines( ls_json_response-transaction ) > 0
                                                             THEN ls_json_response-transaction[ lv_line ]-balance_after_transaction   )
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

    LOOP AT ls_json_response-transaction INTO DATA(ls_transaction).
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no =  lv_sequence_no.
      ls_offline_data-receipt_no  = ls_transaction-transaction_instance_id.
      ls_offline_data-physical_operation_date = ls_transaction-transaction_instance_id(4) &&
                                                ls_transaction-transaction_instance_id+5(2) &&
                                                ls_transaction-transaction_instance_id+8(2).
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-time = ls_transaction-transaction_instance_id+11(2) &&
                             ls_transaction-transaction_instance_id+14(2) &&
                             ls_transaction-transaction_instance_id+17(2).
      ls_offline_data-valor = ls_transaction-value_date.
      ls_offline_data-transaction_type = ls_transaction-transaction_id.
*bankadaki gösterge ile ters çalışması gerekiyor denildi.
      ls_offline_data-debit_credit = COND #( WHEN ls_transaction-txn_credit_debit_indicator = 'A' THEN 'B'
                                             WHEN ls_transaction-txn_credit_debit_indicator = 'B' THEN 'A' ).
      ls_offline_data-description = ls_transaction-explanation.
      ls_offline_data-payee_vkn = ls_transaction-vkn.
      ls_offline_data-debtor_vkn  = ls_transaction-corr_vkn.
      ls_offline_data-amount = ls_transaction-amount.
      IF ls_offline_data-debit_credit = 'A'.
        ls_offline_data-amount = ls_offline_data-amount * -1.
      ENDIF.
      ls_offline_data-current_balance = ls_transaction-balance_after_transaction.
      ls_offline_data-sender_iban = ls_transaction-corr_iban. "lv_corriban.
      ls_offline_data-sender_branch = ls_transaction-corr_unit_num. "lv_corrunitnum.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
  ENDMETHOD.