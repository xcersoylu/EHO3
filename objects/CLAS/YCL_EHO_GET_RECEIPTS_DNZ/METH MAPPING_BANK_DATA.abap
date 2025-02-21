  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_transactions,
              valor                          TYPE string,
              receiptnumber                  TYPE string,
              destinationaccount             TYPE string,
              destinationaccountidenditynumb TYPE string,
              destinationaccounttitle        TYPE string,
              referecencenumber              TYPE string,
              transactionname                TYPE string,
              transactiondetail1             TYPE string,
              transactiondetail2             TYPE string,
              transactiondetail3             TYPE string,
              transactiondetail4             TYPE string,
              transactiondetail5             TYPE string,
              additionalinfo                 TYPE string,
              bankdescription                TYPE string,
              transactioncode                TYPE string,
              subtransactioncode             TYPE string,
              description                    TYPE string,
              channel                        TYPE string,
              balancebeforetransaction       TYPE string,
              balanceaftertransaction        TYPE string,
              amount                         TYPE string,
              ordernumber                    TYPE string,
              time                           TYPE string,
              date                           TYPE string,
              customerno                     TYPE string,
              islemdurumu                    TYPE string,
              debitcredittype                TYPE string,
            END OF ty_transactions,
            tt_transactions TYPE TABLE OF ty_transactions WITH EMPTY KEY,
            BEGIN OF ty_online_accounts,
              maturitydate               TYPE string,
              availablebalancewithcredit TYPE string,
              creditlimit                TYPE string,
              availablebalance           TYPE string,
              blockageamount             TYPE string,
              amountofbalance            TYPE string,
              queryinitialbalance        TYPE string,
              queryfinishbalance         TYPE string,
              lastmodifieddate           TYPE string,
              interestrate               TYPE string,
              accountopenningdate        TYPE string,
              accountnumber              TYPE string,
              accountbranchname          TYPE string,
              accountbranchcode          TYPE string,
              accountcurrencycode        TYPE string,
              accountname                TYPE string,
              accounttype                TYPE string,
              accountsuffix              TYPE string,
              ibannumber                 TYPE string,
              transactions               TYPE tt_transactions,
            END OF ty_online_accounts,
            tt_online_accounts TYPE TABLE OF ty_online_accounts WITH EMPTY KEY,
            BEGIN OF ty_accounts,
              accounts TYPE tt_online_accounts,
            END OF ty_accounts,
            BEGIN OF ty_json,
              data TYPE ty_accounts,
            END OF ty_json.
    DATA ls_json_response TYPE ty_json.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA(lv_json) = iv_json.

    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>horizontal_tab IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>endian         IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>minchar        IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>maxchar        IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>vertical_tab   IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>newline        IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>cr_lf          IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>form_feed      IN lv_json WITH ''.
    REPLACE ALL OCCURRENCES OF  cl_abap_char_utilities=>backspace      IN lv_json WITH ''.

    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-data-accounts INTO DATA(ls_account) WITH KEY ibannumber = ms_bankpass-iban.

*    ls_list-account_amount_type     = ls_account-accounttype.
*    ls_list-last_updated_date_time  = ls_account-lastmodifieddate.

    LOOP AT ls_account-transactions ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no     = lv_sequence_no.
      ls_offline_data-glaccount       = ms_bankpass-glaccount.
      ls_offline_data-amount       = <fs_hareket>-amount.
      ls_offline_data-description    = <fs_hareket>-bankdescription.
      ls_offline_data-debit_credit = <fs_hareket>-debitcredittype.
      DATA(lv_len) = strlen( <fs_hareket>-transactiondetail1 ).
      IF lv_len = 10 OR lv_len = 11.
        IF ls_offline_data-debit_credit = 'B'.
          ls_offline_data-payee_vkn = <fs_hareket>-transactiondetail1.
        ENDIF.
        IF ls_offline_data-debit_credit = 'A'.
          ls_offline_data-debtor_vkn = <fs_hareket>-transactiondetail1.
        ENDIF.
      ENDIF.
      ls_offline_data-current_balance          = <fs_hareket>-balanceaftertransaction.
      ls_offline_data-receipt_no             = <fs_hareket>-receiptnumber.

      IF <fs_hareket>-date IS NOT INITIAL.
        CONCATENATE <fs_hareket>-date+0(4)
                    <fs_hareket>-date+5(2)
                    <fs_hareket>-date+8(2)
               INTO ls_offline_data-physical_operation_date.

        CONCATENATE <fs_hareket>-date+11(2)
                    <fs_hareket>-date+14(2)
                    <fs_hareket>-date+17(2)
               INTO ls_offline_data-time.
      ENDIF.
*
      CONCATENATE <fs_hareket>-valor+11(2)
                  <fs_hareket>-valor+14(2)
                  <fs_hareket>-valor+17(2)
             INTO ls_offline_data-valor.
*
      ls_offline_data-sender_iban      = <fs_hareket>-transactiondetail2.
      ls_offline_data-transaction_type = <fs_hareket>-transactioncode.
      ls_offline_data-sender_branch    = <fs_hareket>-transactiondetail4.
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
      lv_opening_balance  = lv_closing_balance = ls_account-amountofbalance.
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