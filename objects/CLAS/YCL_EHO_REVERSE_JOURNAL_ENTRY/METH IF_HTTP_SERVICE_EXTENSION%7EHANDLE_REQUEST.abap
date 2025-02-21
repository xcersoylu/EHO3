  METHOD if_http_service_extension~handle_request.
    DATA lt_jr  TYPE TABLE FOR ACTION IMPORT i_journalentrytp~reverse.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).

    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).
*daha önce ters kaydı alınmış mı?
    SELECT SINGLE reversedocument
            FROM i_journalentry
            WHERE companycode = @ms_request-companycode
              AND accountingdocument = @ms_request-accountingdocument
              AND fiscalyear = @ms_request-fiscalyear
              AND isreversed = @abap_true
              INTO @DATA(lv_reversedocument).
    IF sy-subrc = 0.
      MESSAGE ID ycl_eho_utils=>mc_message_class TYPE ycl_eho_utils=>mc_error NUMBER 010 WITH lv_reversedocument INTO DATA(lv_message).
      APPEND VALUE #( messagetype = ycl_eho_utils=>mc_warning message = lv_message ) TO ms_response-messages.
    ELSE.
      APPEND INITIAL LINE TO lt_jr ASSIGNING FIELD-SYMBOL(<jr>).
      <jr>-companycode        = ms_request-companycode.
      <jr>-fiscalyear         = ms_request-fiscalyear.
      <jr>-accountingdocument = ms_request-accountingdocument.
      <jr>-%param             = VALUE #( postingdate    = ms_request-postingdate
                                         reversalreason = ms_request-reversalreason
                                         createdbyuser  = COND #( WHEN ms_request-createdbyuser IS INITIAL
                                                                  THEN sy-uname
                                                                  ELSE ms_request-createdbyuser ) ).
      MODIFY ENTITIES OF i_journalentrytp
      ENTITY journalentry
      EXECUTE reverse FROM lt_jr
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported)
      MAPPED DATA(ls_mapped).
      IF ls_failed-journalentry IS INITIAL.
        COMMIT ENTITIES BEGIN
        RESPONSE OF i_journalentrytp
        FAILED DATA(lt_commit_failed)
        REPORTED DATA(lt_commit_reported).
        LOOP AT ls_mapped-journalentry ASSIGNING FIELD-SYMBOL(<ls_mapped>).
          CONVERT KEY OF i_journalentrytp FROM <ls_mapped>-%pid TO DATA(lv_key).
          ms_response-companycode = lv_key-companycode.
          ms_response-fiscalyear = lv_key-fiscalyear.
          ms_response-accountingdocument = lv_key-accountingdocument.
          EXIT.
        ENDLOOP.
        COMMIT ENTITIES END.
        DELETE FROM yeho_t_savedrcpt
               WHERE companycode = @ms_request-companycode
                 AND accountingdocument = @ms_request-accountingdocument
                 AND fiscal_year = @ms_request-fiscalyear.
        COMMIT WORK AND WAIT.
        MESSAGE ID ycl_eho_utils=>mc_message_class TYPE ycl_eho_utils=>mc_success NUMBER 009 WITH ms_response-accountingdocument INTO lv_message.
        APPEND VALUE #( messagetype = ycl_eho_utils=>mc_success message = lv_message ) TO ms_response-messages.
      ELSE.
        LOOP AT ls_reported-journalentry ASSIGNING FIELD-SYMBOL(<ls_reported>).
          lv_message = <ls_reported>-%msg->if_message~get_text( ).
          APPEND VALUE #( messagetype = ycl_eho_utils=>mc_error message = lv_message ) TO ms_response-messages.
        ENDLOOP.
        IF sy-subrc <> 0.
          MESSAGE ID ycl_eho_utils=>mc_message_class TYPE ycl_eho_utils=>mc_error NUMBER 008  INTO lv_message.
          APPEND VALUE #( messagetype = ycl_eho_utils=>mc_error message = lv_message ) TO ms_response-messages.
        ENDIF.
      ENDIF.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).
  ENDMETHOD.