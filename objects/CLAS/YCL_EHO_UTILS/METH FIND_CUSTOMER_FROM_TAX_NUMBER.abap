  METHOD find_customer_from_tax_number.
    SELECT SINGLE customer
              FROM i_customer
              WHERE taxnumber1 = @iv_tax_number
              INTO @rv_customer.
    IF sy-subrc <> 0.
      SELECT SINGLE customer
                FROM i_customer
                WHERE taxnumber2 = @iv_tax_number
                INTO @rv_customer.
    ENDIF.
  ENDMETHOD.