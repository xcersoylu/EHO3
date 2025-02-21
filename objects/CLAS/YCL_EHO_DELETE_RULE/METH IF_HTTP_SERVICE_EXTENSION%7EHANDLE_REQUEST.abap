  METHOD if_http_service_extension~handle_request.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).

    DELETE FROM yeho_t_rules WHERE companycode = @ms_request-companycode
                               AND itemno = @ms_request-rule_no.
    IF sy-subrc = 0.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_success
              NUMBER 014
              INTO DATA(lv_message).
      APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_success ) TO ms_response-messages.
    ELSE.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 015
              INTO lv_message.
      APPEND VALUE #( message = lv_message messagetype =  ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).

  ENDMETHOD.