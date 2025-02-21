  METHOD find_bp_from_iban.
    SELECT SINGLE businesspartner
            FROM i_businesspartnerbank
            WHERE iban = @iv_iban
            INTO @rv_businesspartner.
  ENDMETHOD.