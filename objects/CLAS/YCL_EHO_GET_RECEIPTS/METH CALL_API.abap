  METHOD call_api.
    CONSTANTS lc_success_code TYPE i VALUE 200.
    DATA(lv_json) = fill_json(  ).
    TRY.
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( CONV #( ms_bankpass-cpi_url ) ).
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_authorization_basic(
          EXPORTING
            i_username = CONV #( ms_bankpass-cpi_user )
            i_password = CONV #( ms_bankpass-cpi_password )
        ).

        lo_web_http_request->set_header_fields( VALUE #( (  name = 'Accept' value = 'application/json' )
                                                         (  name = 'Content-Type' value = 'application/json' ) ) ).
        lo_web_http_request->set_text(
          EXPORTING
            i_text   = lv_json
        ).

        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
        DATA(lv_response) = lo_web_http_response->get_text( ).
        ev_original_data = lv_response.
        lo_web_http_response->get_status(
          RECEIVING
            r_value = DATA(ls_status)
        ).
        IF ls_status-code = lc_success_code. "success
          mapping_bank_data(
            EXPORTING
              iv_json         = lv_response
            IMPORTING
              et_bank_data    = et_bank_data
              et_bank_balance = et_bank_balance
          ).
        ELSE.
          MESSAGE ID ycl_eho_utils=>mc_message_class
                  TYPE ycl_eho_utils=>mc_error
                  NUMBER 017
                  WITH ls_status-code
                  INTO DATA(lv_message).
          APPEND VALUE #( message = lv_message messagetype = ycl_eho_utils=>mc_error ) TO et_error_messages.
          APPEND VALUE #( message = lv_response messagetype = ycl_eho_utils=>mc_error ) TO et_error_messages.
        ENDIF.
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.

  ENDMETHOD.