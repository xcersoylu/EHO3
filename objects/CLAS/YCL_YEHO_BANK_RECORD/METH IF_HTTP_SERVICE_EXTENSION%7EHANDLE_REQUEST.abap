  METHOD if_http_service_extension~handle_request.
    DATA lt_header TYPE yeho_tt_bank_record_header.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).
    LOOP AT ms_request-glaccount ASSIGNING FIELD-SYMBOL(<ls_glaccount>).
      IF <ls_glaccount>-low IS NOT INITIAL.
        <ls_glaccount>-low = |{ <ls_glaccount>-low ALPHA = IN }|.
      ENDIF.
      IF <ls_glaccount>-high IS NOT INITIAL.
        <ls_glaccount>-high = |{ <ls_glaccount>-high ALPHA = IN }|.
      ENDIF.
    ENDLOOP.
*EHO dışından atılan kayıtlar için
    SELECT bseg~companycode,
           bseg~accountingdocument,
           bseg~fiscalyear,
           bseg~accountingdocumentitem,
           bkpf~postingdate,
           bseg~absoluteamountintransaccrcy,
           bseg~transactioncurrency,
           bseg~glaccount,
           bseg~debitcreditcode,
           bkpf~transactioncode,
           bkpf~accountingdoccreatedbyuser
       FROM yeho_t_amounttc AS amounttc INNER JOIN i_journalentry AS bkpf ON bkpf~companycode = amounttc~companycode
                                                                         AND bkpf~accountingdocumenttype = amounttc~document_type
                                                                         AND bkpf~transactioncode = amounttc~transaction_code
                                        INNER JOIN i_operationalacctgdocitem AS bseg ON bseg~companycode = bkpf~companycode
                                                                                    AND bseg~accountingdocument = bkpf~accountingdocument
                                                                                    AND bseg~fiscalyear = bkpf~fiscalyear
       WHERE bkpf~postingdate IN @ms_request-date
         AND bkpf~isreversal = ''
         AND bkpf~isreversed = ''
         INTO TABLE @DATA(lt_manual_documents).
***
    SELECT companycode,
           glaccount
      FROM yeho_t_bankpass
      WHERE companycode = @ms_request-companycode
        AND glaccount IN @ms_request-glaccount
      INTO CORRESPONDING FIELDS OF TABLE @lt_header.
    SELECT bankdata~companycode,
           bankdata~glaccount,
           bankdata~valid_from,
           bankdata~bank_code,
           bankcode~bank_name,
           bankdata~account_no,
           bankdata~branch_no,
           bankdata~branch_name_description,
           bankdata~currency,
           bankdata~opening_balance,
           bankdata~closing_balance,
           bankdata~bank_id,
           bankdata~account_id
      FROM yeho_t_offlinebd AS bankdata LEFT OUTER JOIN yeho_t_bankcode AS bankcode ON bankcode~bank_code = bankdata~bank_code
      WHERE bankdata~companycode = @ms_request-companycode
        AND bankdata~glaccount IN @ms_request-glaccount
        AND bankdata~valid_from IN @ms_request-date
       INTO TABLE @DATA(lt_bankdata).
*      INTO CORRESPONDING FIELDS OF TABLE @ms_response-header.
    IF sy-subrc = 0.
      SORT lt_bankdata BY companycode glaccount valid_from ASCENDING.
      DATA(lt_bankdata_min) = lt_bankdata.
      SORT lt_bankdata BY companycode glaccount valid_from  DESCENDING.
      DATA(lt_bankdata_max) = lt_bankdata.

      LOOP AT lt_header INTO DATA(ls_header).
        READ TABLE lt_bankdata_min INTO DATA(ls_bankdata_min) WITH KEY companycode = ls_header-companycode
                                                                       glaccount = ls_header-glaccount.
        IF sy-subrc <> 0. "hareket yoksa ekrana gelmesin
          CONTINUE.
        ENDIF.
        READ TABLE lt_bankdata_max INTO DATA(ls_bankdata_max) WITH KEY companycode = ls_header-companycode
                                                                       glaccount = ls_header-glaccount.
        APPEND VALUE #( companycode = ls_header-companycode
                        glaccount   = ls_header-glaccount
                        bank_code   = ls_bankdata_min-bank_code
                        bank_name   = ls_bankdata_min-bank_name
                        account_no  = ls_bankdata_min-account_no
                        branch_no   = ls_bankdata_min-branch_no
                        branch_name_description = ls_bankdata_min-branch_name_description
                        currency = ls_bankdata_min-currency
                        opening_balance = ls_bankdata_min-opening_balance
                        closing_balance = ls_bankdata_max-closing_balance
                        bank_id         = ls_bankdata_min-bank_id
                        account_id      = ls_bankdata_min-account_id
                        ) TO ms_response-header.
        CLEAR : ls_bankdata_min , ls_bankdata_max.
      ENDLOOP.

      CASE ms_request-record_type.
        WHEN '1'. "muhasebeleşmemiş
          SELECT *
            FROM yeho_t_offlinedt
           WHERE companycode = @ms_request-companycode
             AND glaccount IN @ms_request-glaccount
             AND physical_operation_date IN @ms_request-date
             AND NOT EXISTS ( SELECT * FROM yeho_t_savedrcpt WHERE companycode = yeho_t_offlinedt~companycode
                                                               AND glaccount = yeho_t_offlinedt~glaccount
                                                               AND receipt_no = yeho_t_offlinedt~receipt_no
                                                               AND physical_operation_date = yeho_t_offlinedt~physical_operation_date )
             INTO CORRESPONDING FIELDS OF TABLE @ms_response-items.
*EHO dışından atılan kayıt var mı ?
          IF sy-subrc = 0.

            SELECT mandoc~*
              FROM @ms_response-items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
                                                                                AND mandoc~glaccount = items~glaccount
                                                                                AND mandoc~receipt_no = items~receipt_no
                                                                                AND mandoc~physical_operation_date = items~physical_operation_date
             ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
             INTO TABLE @DATA(lt_mandoc_db).

            LOOP AT ms_response-items ASSIGNING FIELD-SYMBOL(<ls_item>).
              READ TABLE lt_manual_documents INTO DATA(ls_manual_document)
                                             WITH KEY glaccount = <ls_item>-glaccount
                                                      postingdate = <ls_item>-physical_operation_date
                                                      debitcreditcode = COND #( WHEN <ls_item>-debit_credit = 'B' THEN 'S' ELSE 'H' )
                                                      absoluteamountintransaccrcy = abs( <ls_item>-amount ). "#TODO binary search
              IF sy-subrc = 0.
                <ls_item>-manualrecord = abap_true.
                <ls_item>-transactioncode = ls_manual_document-transactioncode.
                <ls_item>-username = ls_manual_document-accountingdoccreatedbyuser.
              ELSE.
                READ TABLE lt_mandoc_db INTO DATA(ls_mandoc_db) WITH KEY companycode = <ls_item>-companycode
                                                                         glaccount = <ls_item>-glaccount
                                                                         receipt_no = <ls_item>-receipt_no
                                                                         physical_operation_date = <ls_item>-physical_operation_date BINARY SEARCH.
                IF sy-subrc = 0.
                  <ls_item>-manualrecord = abap_true.
                ENDIF.
              ENDIF.
            ENDLOOP.
            DELETE ms_response-items WHERE manualrecord = abap_true.
          ENDIF.
        WHEN '2'. "muhasebeleşmiş
          SELECT offlinedata~* , saved~accountingdocument,saved~fiscal_year
            FROM yeho_t_offlinedt AS offlinedata LEFT OUTER JOIN yeho_t_savedrcpt AS saved ON saved~companycode = offlinedata~companycode
                                                                                     AND saved~glaccount = offlinedata~glaccount
                                                                                     AND saved~receipt_no = offlinedata~receipt_no
                                                                                     AND saved~physical_operation_date = offlinedata~physical_operation_date
           WHERE offlinedata~companycode = @ms_request-companycode
             AND offlinedata~glaccount IN @ms_request-glaccount
             AND offlinedata~physical_operation_date IN @ms_request-date
             INTO CORRESPONDING FIELDS OF TABLE @ms_response-items.
*          if ms_response-items is NOT INITIAL.
*            SELECT mandoc~*
*              FROM @ms_response-items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
*                                                                                AND mandoc~glaccount = items~glaccount
*                                                                                AND mandoc~receipt_no = items~receipt_no
*                                                                                AND mandoc~physical_operation_date = items~physical_operation_date
*             ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
*             INTO TABLE @lt_mandoc_db.
*          endif.
          DATA(lt_items) = ms_response-items.
          DELETE lt_items WHERE accountingdocument IS NOT INITIAL.
          IF lt_items IS NOT INITIAL.
            SELECT mandoc~*
              FROM @lt_items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
                                                                                AND mandoc~glaccount = items~glaccount
                                                                                AND mandoc~receipt_no = items~receipt_no
                                                                                AND mandoc~physical_operation_date = items~physical_operation_date
             ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
             INTO TABLE @lt_mandoc_db.
*          ELSE.
*            SELECT *
*              FROM yeho_t_mandoc
*              WHERE companycode = @ms_request-companycode
*                AND glaccount IN @ms_request-glaccount
*                ORDER BY companycode,glaccount,receipt_no,physical_operation_date
*                INTO TABLE @lt_mandoc_db.
          ENDIF.
          LOOP AT ms_response-items ASSIGNING <ls_item> WHERE accountingdocument IS INITIAL.
            READ TABLE lt_manual_documents INTO ls_manual_document
                                           WITH KEY glaccount = <ls_item>-glaccount
                                                    postingdate = <ls_item>-physical_operation_date
                                                    debitcreditcode = COND #( WHEN <ls_item>-debit_credit = 'B' THEN 'S' ELSE 'H' )
                                                    absoluteamountintransaccrcy = abs( <ls_item>-amount ).
            IF sy-subrc = 0.
              <ls_item>-manualrecord = abap_true.
              <ls_item>-transactioncode = ls_manual_document-transactioncode.
              <ls_item>-username = ls_manual_document-accountingdoccreatedbyuser.
              <ls_item>-accountingdocument = ls_manual_document-accountingdocument.
              <ls_item>-fiscal_year = ls_manual_document-fiscalyear.
            ELSE.
              READ TABLE lt_mandoc_db INTO ls_mandoc_db WITH KEY companycode = <ls_item>-companycode
                                                                 glaccount = <ls_item>-glaccount
                                                                 receipt_no = <ls_item>-receipt_no
                                                                 physical_operation_date = <ls_item>-physical_operation_date BINARY SEARCH.
              IF sy-subrc = 0.
                <ls_item>-manualrecord = abap_true.
                <ls_item>-accountingdocument = ls_mandoc_db-accountingdocument.
                <ls_item>-fiscal_year = ls_mandoc_db-fiscalyear.
              ENDIF.
            ENDIF.
          ENDLOOP.
          DELETE ms_response-items WHERE accountingdocument IS INITIAL AND manualrecord IS INITIAL.
        WHEN '3'. "tümü
          SELECT offlinedata~* , saved~accountingdocument,saved~fiscal_year
            FROM yeho_t_offlinedt AS offlinedata LEFT OUTER JOIN yeho_t_savedrcpt AS saved ON saved~companycode = offlinedata~companycode
                                                                                     AND saved~glaccount = offlinedata~glaccount
                                                                                     AND saved~receipt_no = offlinedata~receipt_no
                                                                                     AND saved~physical_operation_date = offlinedata~physical_operation_date
           WHERE offlinedata~companycode = @ms_request-companycode
             AND offlinedata~glaccount IN @ms_request-glaccount
             AND offlinedata~physical_operation_date IN @ms_request-date
             INTO CORRESPONDING FIELDS OF TABLE @ms_response-items.
*          if ms_response-items is NOT INITIAL.
*            SELECT mandoc~*
*              FROM @ms_response-items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
*                                                                                AND mandoc~glaccount = items~glaccount
*                                                                                AND mandoc~receipt_no = items~receipt_no
*                                                                                AND mandoc~physical_operation_date = items~physical_operation_date
*             ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
*             INTO TABLE @lt_mandoc_db.
*          endif.
          lt_items = ms_response-items.
          DELETE lt_items WHERE accountingdocument IS NOT INITIAL.
          IF lt_items IS NOT INITIAL.
            SELECT mandoc~*
              FROM @lt_items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
                                                                                AND mandoc~glaccount = items~glaccount
                                                                                AND mandoc~receipt_no = items~receipt_no
                                                                                AND mandoc~physical_operation_date = items~physical_operation_date
             ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
             INTO TABLE @lt_mandoc_db.
*          ELSE.
*            SELECT *
*              FROM yeho_t_mandoc
*              WHERE companycode = @ms_request-companycode
*                AND glaccount IN @ms_request-glaccount
*                ORDER BY companycode,glaccount,receipt_no,physical_operation_date
*                INTO TABLE @lt_mandoc_db.
          ENDIF.

          LOOP AT ms_response-items ASSIGNING <ls_item> WHERE accountingdocument IS INITIAL.
            READ TABLE lt_manual_documents INTO ls_manual_document
                                           WITH KEY glaccount = <ls_item>-glaccount
                                                    postingdate = <ls_item>-physical_operation_date
                                                    debitcreditcode = COND #( WHEN <ls_item>-debit_credit = 'B' THEN 'S' ELSE 'H' )
                                                    absoluteamountintransaccrcy = abs( <ls_item>-amount ).
            IF sy-subrc = 0.
              <ls_item>-manualrecord = abap_true.
              <ls_item>-transactioncode = ls_manual_document-transactioncode.
              <ls_item>-username = ls_manual_document-accountingdoccreatedbyuser.
              <ls_item>-accountingdocument = ls_manual_document-accountingdocument.
              <ls_item>-fiscal_year = ls_manual_document-fiscalyear.
            ELSE.
              READ TABLE lt_mandoc_db INTO ls_mandoc_db WITH KEY companycode = <ls_item>-companycode
                                                                 glaccount = <ls_item>-glaccount
                                                                 receipt_no = <ls_item>-receipt_no
                                                                 physical_operation_date = <ls_item>-physical_operation_date BINARY SEARCH.
              IF sy-subrc = 0.
                <ls_item>-manualrecord = abap_true.
                <ls_item>-accountingdocument = ls_mandoc_db-accountingdocument.
                <ls_item>-fiscal_year = ls_mandoc_db-fiscalyear.
              ENDIF.
            ENDIF.
          ENDLOOP.
      ENDCASE.
      get_rule(
        CHANGING
          ct_items = ms_response-items
      ).
    ENDIF.
    SORT ms_response-items BY physical_operation_date ASCENDING time ASCENDING.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).

  ENDMETHOD.