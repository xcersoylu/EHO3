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
              specialglcode                 TYPE yeho_e_umskz,
              documentitemtext              TYPE sgtxt,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_glitem,
            BEGIN OF ty_aritems, "kunnr
              glaccountlineitem             TYPE string,
              customer                      TYPE kunnr,
              paymentmethod                 TYPE dzlsch,
              paymentterms                  TYPE dzterm,
              assignmentreference           TYPE dzuonr,
              profitcenter                  TYPE prctr,
              creditcontrolarea             TYPE kkber,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              specialglcode                 TYPE yeho_e_umskz,
              documentitemtext              TYPE sgtxt,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_aritems,
            BEGIN OF ty_apitems, "lifnr
              glaccountlineitem             TYPE string,
              supplier                      TYPE lifnr,
              paymentmethod                 TYPE dzlsch,
              paymentterms                  TYPE dzterm,
              assignmentreference           TYPE dzuonr,
              profitcenter                  TYPE prctr,
              creditcontrolarea             TYPE kkber,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              specialglcode                 TYPE yeho_e_umskz,
              documentitemtext              TYPE sgtxt,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_apitems.
    DATA lt_je             TYPE TABLE FOR ACTION IMPORT i_journalentrytp~post.
    DATA lt_glitem         TYPE TABLE OF ty_glitem.
    DATA lt_apitem         TYPE TABLE OF ty_apitems.
    DATA lt_aritem         TYPE TABLE OF ty_aritems.
    DATA lt_saved_receipts TYPE TABLE OF yeho_t_savedrcpt.
    DATA lv_buzei TYPE buzei.
    DATA lv_wrbtr TYPE yeho_e_wrbtr.
    DATA lv_wrbtr_total TYPE yeho_e_wrbtr.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).

    APPEND INITIAL LINE TO lt_je ASSIGNING FIELD-SYMBOL(<fs_je>).
    TRY.
        <fs_je>-%cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
        lv_buzei = 1.
        LOOP AT ms_request-split_items INTO DATA(ls_split_item).
          lv_buzei += 1.
          lv_wrbtr = COND #( WHEN ls_split_item-debit_credit = 'B' THEN -1 * ls_split_item-amount
                                                                   ELSE ls_split_item-amount ).
          lv_wrbtr_total += lv_wrbtr.
          IF ls_split_item-supplier IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = lv_buzei
                            supplier                      = ls_split_item-supplier
                            paymentmethod                 = ls_split_item-paymentmethod
                            paymentterms                  = ls_split_item-paymentterms
                            assignmentreference           = ls_split_item-assignmentreference
                            profitcenter                  = ls_split_item-profitcenter
                            creditcontrolarea             = ls_split_item-creditcontrolarea
                            reference1idbybusinesspartner = ls_split_item-reference1idbybusinesspartner
                            reference2idbybusinesspartner = ls_split_item-reference2idbybusinesspartner
                            reference3idbybusinesspartner = ls_split_item-reference3idbybusinesspartner
                            specialglcode                 = ls_split_item-specialglcode
                            documentitemtext              = ls_split_item-documentitemtext
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = lv_wrbtr
                                                        currency = ls_split_item-currency  ) ) ) TO lt_apitem.
          ELSEIF ls_split_item-customer IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = lv_buzei
                            customer                      = ls_split_item-customer
                            paymentmethod                 = ls_split_item-paymentmethod
                            paymentterms                  = ls_split_item-paymentterms
                            assignmentreference           = ls_split_item-assignmentreference
                            profitcenter                  = ls_split_item-profitcenter
                            creditcontrolarea             = ls_split_item-creditcontrolarea
                            reference1idbybusinesspartner = ls_split_item-reference1idbybusinesspartner
                            reference2idbybusinesspartner = ls_split_item-reference2idbybusinesspartner
                            reference3idbybusinesspartner = ls_split_item-reference3idbybusinesspartner
                            specialglcode                 = ls_split_item-specialglcode
                            documentitemtext              = ls_split_item-documentitemtext
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = lv_wrbtr
                                                        currency = ms_request-selected_line-currency  ) ) ) TO lt_aritem.
          ELSEIF ls_split_item-glaccount IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = lv_buzei
                            glaccount                     = ls_split_item-glaccount
                            assignmentreference           = ls_split_item-assignmentreference
                            reference1idbybusinesspartner = ls_split_item-reference1idbybusinesspartner
                            reference2idbybusinesspartner = ls_split_item-reference2idbybusinesspartner
                            reference3idbybusinesspartner = ls_split_item-reference3idbybusinesspartner
                            costcenter                    = ls_split_item-costcenter
                            orderid                       = ls_split_item-orderid
                            specialglcode                 = ls_split_item-specialglcode
                            documentitemtext              = ls_split_item-documentitemtext
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = lv_wrbtr
                                                        currency = ls_split_item-currency  ) )          ) TO lt_glitem.
          ENDIF.
        ENDLOOP.

        APPEND VALUE #( glaccountlineitem             = |001|
                        glaccount                     = ms_request-selected_line-glaccount
                        assignmentreference           = ms_request-selected_line-assignmentreference
*                        reference1idbybusinesspartner = ms_request-selected_line-reference1idbybusinesspartner
*                        reference2idbybusinesspartner = ms_request-selected_line-reference2idbybusinesspartner
*                        reference3idbybusinesspartner = ms_request-selected_line-reference3idbybusinesspartner
                        costcenter                    = ms_request-selected_line-costcenter
                        _currencyamount = VALUE #( ( currencyrole = '00'
                                                    journalentryitemamount = COND #( WHEN lv_wrbtr_total < 0 THEN abs( ms_request-selected_line-amount )
                                                                                                             ELSE -1 * abs( ms_request-selected_line-amount ) )
                                                    currency = ms_request-selected_line-currency  ) )          ) TO lt_glitem.

        <fs_je>-%param = VALUE #( companycode                  = ms_request-selected_line-companycode
                                  documentreferenceid          = ms_request-document_header-documentreferenceid
                                  createdbyuser                = sy-uname
                                  businesstransactiontype      = 'RFBU'
                                  accountingdocumenttype       = ms_request-document_header-documenttype
                                  documentdate                 = ms_request-selected_line-physical_operation_date
                                  postingdate                  = ms_request-selected_line-physical_operation_date
                                  accountingdocumentheadertext = ms_request-document_header-accountingdocumentheadertext
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
          ms_response-messages = VALUE #( FOR wa IN ls_reported-journalentry ( message = wa-%msg->if_message~get_text( ) messagetype = mc_error ) ).
        ELSE.
          COMMIT ENTITIES BEGIN
           RESPONSE OF i_journalentrytp
           FAILED DATA(ls_commit_failed)
           REPORTED DATA(ls_commit_reported).
          COMMIT ENTITIES END.
          IF ls_commit_failed IS INITIAL.
            ms_response-accountingdocument = VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL ).
            ms_response-fiscal_year = VALUE #( ls_commit_reported-journalentry[ 1 ]-fiscalyear OPTIONAL ).
            MESSAGE ID ycl_eho_utils=>mc_message_class
                  TYPE ycl_eho_utils=>mc_success
                NUMBER 016
                  WITH ms_response-accountingdocument
                  INTO DATA(lv_message).
            APPEND VALUE #( messagetype = ycl_eho_utils=>mc_success message = lv_message ) TO ms_response-messages.
            APPEND VALUE #( companycode             = ms_request-selected_line-companycode
                            glaccount               = ms_request-selected_line-glaccount
                            receipt_no              = ms_request-selected_line-receipt_no
                            physical_operation_date = ms_request-selected_line-physical_operation_date
                            accountingdocument      = VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL )
                            fiscal_year             = VALUE #( ls_commit_reported-journalentry[ 1 ]-fiscalyear OPTIONAL ) ) TO lt_saved_receipts.

          ELSE.
            ms_response-messages = VALUE #( FOR wa_commit IN ls_commit_reported-journalentry ( message = wa_commit-%msg->if_message~get_text( ) messagetype = mc_error ) ).
          ENDIF.
        ENDIF.
        CLEAR lt_je.
        CLEAR : ls_failed , ls_reported , ls_commit_failed , ls_commit_reported.
      CATCH cx_uuid_error INTO DATA(lx_error).
        APPEND VALUE #( message = lx_error->get_longtext(  ) messagetype = mc_error ) TO ms_response-messages.
    ENDTRY.
    IF lt_saved_receipts[] IS NOT INITIAL.
      INSERT yeho_t_savedrcpt FROM TABLE @lt_saved_receipts.
      COMMIT WORK AND WAIT.
    ENDIF.

    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).

  ENDMETHOD.