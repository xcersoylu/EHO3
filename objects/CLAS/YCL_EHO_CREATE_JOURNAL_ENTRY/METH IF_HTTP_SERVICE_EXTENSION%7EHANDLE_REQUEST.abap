  METHOD if_http_service_extension~handle_request.

    TYPES : BEGIN OF ty_currencyamount,
              currencyrole           TYPE string,
              journalentryitemamount TYPE yeho_e_wrbtr,
              currency               TYPE waers,
            END OF ty_currencyamount.
    TYPES tt_currencyamount TYPE TABLE OF ty_currencyamount WITH EMPTY KEY.
    TYPES : BEGIN OF ty_glitem,
              glaccountlineitem             TYPE string,
              glaccount                     TYPE saknr,
              assignmentreference           TYPE dzuonr,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              costcenter                    TYPE kostl,
              orderid                       TYPE aufnr,
              documentitemtext              TYPE sgtxt,
              specialglcode                 TYPE yeho_e_umskz,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_glitem,
            BEGIN OF ty_aritems, "kunnr
              glaccountlineitem             TYPE string,
              customer                      TYPE kunnr,
              glaccount                     TYPE hkont,
              paymentmethod                 TYPE dzlsch,
              paymentterms                  TYPE dzterm,
              assignmentreference           TYPE dzuonr,
              profitcenter                  TYPE prctr,
              creditcontrolarea             TYPE kkber,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              documentitemtext              TYPE sgtxt,
              specialglcode                 TYPE yeho_e_umskz,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_aritems,
            BEGIN OF ty_apitems, "lifnr
              glaccountlineitem             TYPE string,
              supplier                      TYPE lifnr,
              glaccount                     TYPE hkont,
              paymentmethod                 TYPE dzlsch,
              paymentterms                  TYPE dzterm,
              assignmentreference           TYPE dzuonr,
              profitcenter                  TYPE prctr,
              creditcontrolarea             TYPE kkber,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              documentitemtext              TYPE sgtxt,
              specialglcode                 TYPE yeho_e_umskz,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_apitems.

    DATA lt_je             TYPE TABLE FOR ACTION IMPORT i_journalentrytp~post.
    DATA lt_glitem         TYPE TABLE OF ty_glitem.
    DATA lt_apitem         TYPE TABLE OF ty_apitems.
    DATA lt_aritem         TYPE TABLE OF ty_aritems.
    DATA lt_saved_receipts TYPE TABLE OF yeho_t_savedrcpt.


    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).

    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).
*    DATA(lt_rule_data) = get_rule_data( it_items = ms_request-items ).
    LOOP AT ms_request-items ASSIGNING FIELD-SYMBOL(<ls_item>).
*      READ TABLE lt_rule_data INTO DATA(ls_rule_data) WITH KEY companycode = <ls_item>-companycode
*                                                               rule_no = <ls_item>-rule_no BINARY SEARCH.
      APPEND INITIAL LINE TO lt_je ASSIGNING FIELD-SYMBOL(<fs_je>).
      TRY.
          <fs_je>-%cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
          APPEND VALUE #( glaccountlineitem             = |001|
                          glaccount                     = <ls_item>-glaccount
                          assignmentreference           = <ls_item>-assignmentreference
                          reference1idbybusinesspartner = <ls_item>-reference1idbybusinesspartner
                          reference2idbybusinesspartner = <ls_item>-reference2idbybusinesspartner
                          reference3idbybusinesspartner = <ls_item>-reference3idbybusinesspartner
                          costcenter                    = <ls_item>-costcenter
                          documentitemtext              = <ls_item>-documentitemtext102
                          _currencyamount = VALUE #( ( currencyrole = '00'
                                                      journalentryitemamount = <ls_item>-amount
                                                      currency = <ls_item>-currency  ) )          ) TO lt_glitem.
          IF <ls_item>-supplier IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = |002|
                            supplier                      = <ls_item>-supplier
                            glaccount                     = <ls_item>-reconciliationaccount
                            paymentmethod                 = <ls_item>-paymentmethod
                            paymentterms                  = <ls_item>-paymentterms
                            assignmentreference           = <ls_item>-assignmentreference
                            profitcenter                  = <ls_item>-profitcenter
                            creditcontrolarea             = <ls_item>-creditcontrolarea
                            reference1idbybusinesspartner = <ls_item>-reference1idbybusinesspartner
                            reference2idbybusinesspartner = <ls_item>-reference2idbybusinesspartner
                            reference3idbybusinesspartner = <ls_item>-reference3idbybusinesspartner
                            documentitemtext              = <ls_item>-documentitemtext
                            specialglcode                 = <ls_item>-specialglcode
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                       journalentryitemamount = -1 * <ls_item>-amount
                                                       currency = <ls_item>-currency  ) ) ) TO lt_apitem.
          ELSEIF <ls_item>-customer IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem              = |002|
                            customer                       = <ls_item>-customer
                             glaccount                     = <ls_item>-reconciliationaccount
                             paymentmethod                 = <ls_item>-paymentmethod
                             paymentterms                  = <ls_item>-paymentterms
                             assignmentreference           = <ls_item>-assignmentreference
                             profitcenter                  = <ls_item>-profitcenter
                             creditcontrolarea             = <ls_item>-creditcontrolarea
                             reference1idbybusinesspartner = <ls_item>-reference1idbybusinesspartner
                             reference2idbybusinesspartner = <ls_item>-reference2idbybusinesspartner
                             reference3idbybusinesspartner = <ls_item>-reference3idbybusinesspartner
                             documentitemtext              = <ls_item>-documentitemtext
                             specialglcode                 = <ls_item>-specialglcode
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = -1 * <ls_item>-amount
                                                        currency = <ls_item>-currency  ) ) ) TO lt_aritem.
          ELSEIF <ls_item>-operationalglaccount IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = |002|
                            glaccount                     = <ls_item>-operationalglaccount
                            assignmentreference           = <ls_item>-assignmentreference
                            reference1idbybusinesspartner = <ls_item>-reference1idbybusinesspartner
                            reference2idbybusinesspartner = <ls_item>-reference2idbybusinesspartner
                            reference3idbybusinesspartner = <ls_item>-reference3idbybusinesspartner
                            costcenter                    = <ls_item>-costcenter
                            orderid                       = <ls_item>-orderid
                            documentitemtext              = <ls_item>-documentitemtext
                            specialglcode                 = <ls_item>-specialglcode
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = -1 * <ls_item>-amount
                                                        currency = <ls_item>-currency  ) )          ) TO lt_glitem.
          ENDIF.
          <fs_je>-%param = VALUE #( companycode                  = <ls_item>-companycode
                                    documentreferenceid          = <ls_item>-documentreferenceid
                                    createdbyuser                = sy-uname
                                    businesstransactiontype      = 'RFBU'
                                    accountingdocumenttype       = <ls_item>-document_type
                                    documentdate                 = <ls_item>-physical_operation_date
                                    postingdate                  = <ls_item>-physical_operation_date
                                    accountingdocumentheadertext = <ls_item>-accountingdocumentheadertext
                                    _apitems                     = VALUE #( FOR wa_apitem  IN lt_apitem  ( CORRESPONDING #( wa_apitem  MAPPING _currencyamount = _currencyamount ) ) )
                                    _aritems                     = VALUE #( FOR wa_aritem  IN lt_aritem  ( CORRESPONDING #( wa_aritem  MAPPING _currencyamount = _currencyamount ) ) )
                                    _glitems                     = VALUE #( FOR wa_glitem  IN lt_glitem  ( CORRESPONDING #( wa_glitem  MAPPING _currencyamount = _currencyamount ) ) )
                                  ).
          MODIFY ENTITIES OF i_journalentrytp
           ENTITY journalentry
           EXECUTE post FROM lt_je
           FAILED DATA(ls_failed)
           REPORTED DATA(ls_reported)
           MAPPED DATA(ls_mapped).
          IF ls_failed IS NOT INITIAL.
            ms_response-messages = VALUE #( base ms_response-messages FOR wa IN ls_reported-journalentry ( message = wa-%msg->if_message~get_text( ) messagetype = mc_error ) ).
          ELSE.
            COMMIT ENTITIES BEGIN
             RESPONSE OF i_journalentrytp
             FAILED DATA(ls_commit_failed)
             REPORTED DATA(ls_commit_reported).
            COMMIT ENTITIES END.
            IF ls_commit_failed IS INITIAL.
              MESSAGE ID ycl_eho_utils=>mc_message_class
                      TYPE ycl_eho_utils=>mc_success
                      NUMBER 016
                      WITH VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL )
                      INTO DATA(lv_message).
              APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_success ) TO ms_response-messages.
              APPEND VALUE #( companycode             = <ls_item>-companycode
                              glaccount               = <ls_item>-glaccount
                              receipt_no              = <ls_item>-receipt_no
                              physical_operation_date = <ls_item>-physical_operation_date
                              accountingdocument      = VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL )
                              fiscal_year             = VALUE #( ls_commit_reported-journalentry[ 1 ]-fiscalyear OPTIONAL ) ) TO ms_response-journal_entry.
              APPEND VALUE #( companycode             = <ls_item>-companycode
                              glaccount               = <ls_item>-glaccount
                              receipt_no              = <ls_item>-receipt_no
                              physical_operation_date = <ls_item>-physical_operation_date
                              accountingdocument      = VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL )
                              fiscal_year             = VALUE #( ls_commit_reported-journalentry[ 1 ]-fiscalyear OPTIONAL ) ) TO lt_saved_receipts.

            ELSE.
              ms_response-messages = VALUE #( base ms_response-messages FOR wa_commit IN ls_commit_reported-journalentry ( message = wa_commit-%msg->if_message~get_text( ) messagetype = mc_error ) ).
            ENDIF.
          ENDIF.
          CLEAR : lt_je, lt_glitem , lt_apitem , lt_aritem , ls_failed , ls_reported , ls_commit_failed , ls_commit_reported.
        CATCH cx_uuid_error INTO DATA(lx_error).
          APPEND VALUE #( message = lx_error->get_longtext(  ) messagetype = mc_error ) TO ms_response-messages.
      ENDTRY.
    ENDLOOP.
    IF lt_saved_receipts[] IS NOT INITIAL.
      INSERT yeho_t_savedrcpt FROM TABLE @lt_saved_receipts.
      COMMIT WORK AND WAIT.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).
  ENDMETHOD.