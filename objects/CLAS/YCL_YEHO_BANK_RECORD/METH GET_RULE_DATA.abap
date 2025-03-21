  METHOD get_rule_data.
    SELECT SINGLE * FROM yeho_t_rules
    WHERE companycode = @ms_request-companycode
      AND itemno = @iv_rule_no
    INTO CORRESPONDING FIELDS OF @rs_result.
  ENDMETHOD.