  METHOD get_branch_name.
    DATA lv_bankinternalid TYPE bankl.
    lv_bankinternalid = |{ iv_bank_code ALPHA = IN }| && '-' && |{ iv_branch_code ALPHA = IN }|.

    SELECT SINGLE bankbranch
      FROM i_bank_2 INNER JOIN i_companycode ON i_bank_2~bankcountry EQ  i_companycode~country
      WHERE bankinternalid EQ  @lv_bankinternalid
        AND companycode EQ @iv_companycode
     INTO @rv_branch_name.
  ENDMETHOD.