  METHOD get_rule_data.
    DATA(lt_lines) = it_items.
    DELETE lt_lines WHERE rule_no IS INITIAL.
    CHECK lt_lines IS NOT INITIAL.
    SELECT rules~*
      FROM @lt_lines AS lines INNER JOIN yeho_t_rules AS rules ON rules~companycode = lines~companycode
                                                              AND rules~itemno = lines~rule_no
     ORDER BY rules~companycode , rules~itemno
     INTO CORRESPONDING FIELDS OF TABLE @rt_rule_data.

  ENDMETHOD.