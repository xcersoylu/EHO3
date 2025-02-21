  METHOD get_bank_name.
    SELECT SINGLE bank_name FROM yeho_t_bankcode WHERE bank_code = @iv_bank_code INTO @rv_bank_name.
  ENDMETHOD.