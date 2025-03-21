  METHOD get_rule.
    TYPES : BEGIN OF ty_glaccount,
              sign   TYPE bapisign,
              option TYPE bapioption,
              low    TYPE hkont,
              high   TYPE hkont,
            END OF ty_glaccount.
    TYPES : BEGIN OF ty_transaction_type,
              sign   TYPE bapisign,
              option TYPE bapioption,
              low    TYPE yeho_e_transaction_type,
              high   TYPE yeho_e_transaction_type,
            END OF ty_transaction_type.
    TYPES : BEGIN OF ty_tax_number,
              sign   TYPE bapisign,
              option TYPE bapioption,
              low    TYPE stcd1,
              high   TYPE stcd1,
            END OF ty_tax_number.
    TYPES : BEGIN OF ty_iban,
              sign   TYPE bapisign,
              option TYPE bapioption,
              low    TYPE yeho_e_char50,
              high   TYPE yeho_e_char50,
            END OF ty_iban.
    TYPES : BEGIN OF ty_debit_credit,
              sign   TYPE bapisign,
              option TYPE bapioption,
              low    TYPE yeho_e_debit_credit,
              high   TYPE yeho_e_debit_credit,
            END OF ty_debit_credit.
    TYPES tt_glaccount TYPE TABLE OF ty_glaccount.
    TYPES tt_transaction_type TYPE TABLE OF ty_transaction_type.
    TYPES tt_tax_number TYPE TABLE OF ty_tax_number.
    TYPES tt_iban TYPE TABLE OF ty_iban.
    TYPES tt_debit_credit TYPE TABLE OF ty_debit_credit.
    DATA lr_glaccount TYPE tt_glaccount.
    DATA lr_transaction_type TYPE tt_transaction_type.
    DATA lr_tax_number TYPE tt_tax_number.
    DATA lr_iban TYPE tt_iban.
    DATA lr_debit_credit TYPE tt_debit_credit.
    DATA lv_documentitemtext TYPE string.
    SELECT * FROM yeho_t_rules
             WHERE companycode = @ms_request-companycode
              INTO TABLE @DATA(lt_rules).
    IF sy-subrc = 0.
      LOOP AT ct_items ASSIGNING FIELD-SYMBOL(<ls_item>).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <ls_item>-glaccount ) TO lr_glaccount.
        APPEND VALUE #( sign = 'I' option = 'EQ' low = '*' ) TO lr_glaccount.
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <ls_item>-transaction_type ) TO lr_transaction_type.
        APPEND VALUE #( sign = 'I' option = 'EQ' low = '*' ) TO lr_transaction_type.
        LOOP AT lt_rules INTO DATA(ls_rule) WHERE account_no_102 IN lr_glaccount
                                              AND transaction_type IN lr_transaction_type
                                              AND tax_number IN lr_tax_number "#TODO bu kısmı doldur
                                              AND iban IN lr_iban
                                              AND debit_credit_indicator IN lr_debit_credit.
          lv_documentitemtext = |*{ ls_rule-documentitemtext }*|.
          IF <ls_item>-description CP lv_documentitemtext.
            <ls_item>-rule_no = ls_rule-itemno.
            <ls_item>-rule_data = get_rule_data( <ls_item>-rule_no ).
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.