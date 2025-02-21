  METHOD if_http_service_extension~handle_request.
    DATA ls_rule TYPE yeho_t_rules.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).

    IF ms_request-rule_data-companycode IS INITIAL.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 002
              WITH ms_response-rule_no
              INTO DATA(lv_message).
      APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    IF ms_request-rule_data-account_no IS INITIAL and
       ms_request-rule_data-customer IS INITIAL and
       ms_request-rule_data-supplier IS INITIAL.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 012
              WITH ms_response-rule_no
              INTO lv_message.
      APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    IF ms_request-rule_data-document_type IS INITIAL.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 013
              WITH ms_response-rule_no
              INTO lv_message.
      APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    IF ms_response-messages IS INITIAL.
      IF ms_request-rule_data-rule_no > 0. "güncelleme.
        ls_rule = CORRESPONDING #( ms_request-rule_data MAPPING itemno = rule_no ).
        MODIFY yeho_t_rules FROM @ls_rule.
        IF sy-subrc = 0.
          ms_response-rule_no = ls_rule-itemno.
          MESSAGE ID ycl_eho_utils=>mc_message_class
                  TYPE ycl_eho_utils=>mc_success
                  NUMBER 007
                  WITH ms_response-rule_no
                  INTO lv_message.
          APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_success ) TO ms_response-messages.
          COMMIT WORK AND WAIT.
        ENDIF.
      ELSE.
        SELECT SINGLE MAX( itemno )
        FROM yeho_t_rules
        WHERE companycode = @ms_request-rule_data-companycode
        INTO @DATA(lv_rule_no).
        IF  sy-subrc = 0.
          lv_rule_no += 1.
        ELSE.
          lv_rule_no = 1.
        ENDIF.
        ls_rule = CORRESPONDING #( ms_request-rule_data ).
        ls_rule-itemno = lv_rule_no.

        INSERT yeho_t_rules FROM @ls_rule.
        IF sy-subrc = 0.
          COMMIT WORK AND WAIT.
          ms_response-rule_no = lv_rule_no.
          MESSAGE ID ycl_eho_utils=>mc_message_class
                  TYPE ycl_eho_utils=>mc_success
                  NUMBER 006
                  WITH ms_response-rule_no
                  INTO lv_message.
          APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_success ) TO ms_response-messages.
        ENDIF.
      ENDIF.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).

  ENDMETHOD.