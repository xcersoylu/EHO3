  METHOD if_http_service_extension~handle_request.
    TYPES : BEGIN OF ty_branch_name,
              companycode TYPE bukrs,
              bank_code   TYPE yeho_e_bank_code,
              branch_code TYPE yeho_e_branch_code,
              branch_name TYPE brnch,
            END OF ty_branch_name.
    DATA lv_startdate        TYPE datum.
    DATA lv_enddate          TYPE datum.
    DATA lt_bank_data        TYPE yeho_tt_offline_bank_data.
    DATA lt_bank_balance     TYPE yeho_tt_offlinebd.
    DATA lt_bank_data_all    TYPE yeho_tt_offline_bank_data.
    DATA lt_bank_balance_all TYPE yeho_tt_offlinebd.
    DATA lv_original_data    TYPE string.
    DATA lv_branch_name      TYPE brnch.
    DATA lt_branch_name      TYPE SORTED TABLE OF ty_branch_name WITH UNIQUE KEY companycode bank_code branch_code.
    DATA lt_error_messages TYPE yeho_tt_message.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).
    lv_enddate = ms_request-enddate.
    lv_startdate = ms_request-startdate.
    LOOP AT ms_request-glaccount ASSIGNING FIELD-SYMBOL(<ls_glaccount>).
      IF <ls_glaccount>-low IS NOT INITIAL.
        <ls_glaccount>-low = |{ <ls_glaccount>-low ALPHA = IN }|.
      ENDIF.
      IF <ls_glaccount>-high IS NOT INITIAL.
        <ls_glaccount>-high = |{ <ls_glaccount>-high ALPHA = IN }|.
      ENDIF.
    ENDLOOP.
    IF ms_request-companycode IS INITIAL.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 002
              INTO DATA(lv_message).
      APPEND VALUE #( message = lv_message messagetype = ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    IF lv_enddate IS NOT INITIAL AND lv_enddate < lv_startdate.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 003
              INTO lv_message.
      APPEND VALUE #( message = lv_message messagetype = ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    IF lv_startdate > cl_abap_context_info=>get_system_date(  ).
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 004
              INTO lv_message.
      APPEND VALUE #( message = lv_message messagetype = ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    SELECT * FROM yeho_t_bankpass
             WHERE companycode = @ms_request-companycode
               AND glaccount IN @ms_request-glaccount
               INTO TABLE @DATA(lt_bankpass).
    IF sy-subrc <> 0.
      MESSAGE ID ycl_eho_utils=>mc_message_class
              TYPE ycl_eho_utils=>mc_error
              NUMBER 005
              INTO lv_message.
      APPEND VALUE #( message = lv_message messagetype = ycl_eho_utils=>mc_error ) TO ms_response-messages.
    ENDIF.
    SELECT housebank~companycode , housebank~glaccount , housebank~bankname,housebank~bankaccountdescription
    FROM @lt_bankpass AS bankpass INNER JOIN i_housebankaccountlinkage AS housebank ON housebank~companycode = bankpass~companycode
                                                                                   AND housebank~glaccount = bankpass~glaccount
    INTO TABLE @DATA(lt_bank_info).

    IF ms_response-messages IS INITIAL.
      DO.
        IF lv_enddate < lv_startdate.
          EXIT.
        ENDIF.
        LOOP AT lt_bankpass INTO DATA(ls_bankpass).
          CLEAR : lt_bank_data , lt_bank_balance , lv_original_data ,lt_error_messages.
          ycl_eho_get_receipts=>factory(
            EXPORTING
              is_bankpass = ls_bankpass
              iv_startdate = ms_request-startdate
              iv_enddate = ms_request-enddate
            RECEIVING
              ro_object   = DATA(lo_object)
          ).
          lo_object->call_api(
            IMPORTING
              et_bank_data = lt_bank_data
              et_bank_balance = lt_bank_balance
              ev_original_data = lv_original_data
              et_error_messages = lt_error_messages
          ).
          IF lt_error_messages IS INITIAL.
            IF lt_bank_data IS NOT INITIAL OR lt_bank_balance IS NOT INITIAL.
              CLEAR lv_branch_name.
              READ TABLE lt_branch_name INTO DATA(ls_branch_name) WITH TABLE KEY companycode = ls_bankpass-companycode
                                                                                 bank_code   = ls_bankpass-bank_code
                                                                                 branch_code = ls_bankpass-branch_code.
              IF sy-subrc = 0.
                lv_branch_name = ls_branch_name-branch_name.
              ELSE.
                lv_branch_name = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ls_bankpass-companycode
                                                iv_bank_code   = ls_bankpass-bank_code
                                                iv_branch_code = ls_bankpass-branch_code ).
                INSERT VALUE #( companycode = ls_bankpass-companycode
                                bank_code   = ls_bankpass-bank_code
                                branch_code = ls_bankpass-branch_code
                                branch_name = lv_branch_name ) INTO TABLE lt_branch_name.
              ENDIF.
              APPEND VALUE #( glaccount           = ls_bankpass-glaccount
                              bank_code           = ls_bankpass-bank_code
                              bank_name           = ycl_eho_utils=>get_bank_name( ls_bankpass-bank_code )
                              branch_code         = ls_bankpass-branch_code
                              branch_name         = lv_branch_name
                              date                = cl_abap_context_info=>get_system_date( )
                              time                = cl_abap_context_info=>get_system_time(  )
                              original_data       = lv_original_data
                              original_data_type  = 'JSON'  ) TO ms_response-receipt_api_data.
              APPEND LINES OF lt_bank_data TO lt_bank_data_all.
              APPEND LINES OF lt_bank_balance TO lt_bank_balance_all.
            ENDIF.
          ELSE.
            APPEND LINES OF lt_error_messages TO ms_response-messages.
          ENDIF.
        ENDLOOP.
        lv_startdate += 1.
      ENDDO.
      IF lt_bank_data_all IS NOT INITIAL.
        MODIFY yeho_t_offlinedt FROM TABLE @lt_bank_data_all.
        COMMIT WORK AND WAIT.
      ENDIF.
      IF lt_bank_balance_all IS NOT INITIAL.
        MODIFY yeho_t_offlinebd FROM TABLE @lt_bank_balance_all.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).
  ENDMETHOD.