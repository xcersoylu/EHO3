  METHOD if_http_service_extension~handle_request.
    DATA lt_deleted TYPE TABLE OF yeho_t_mandoc.
    DATA lt_inserted TYPE TABLE OF yeho_t_mandoc.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).

    SELECT mandoc~*
      FROM @ms_request-items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
                                                                        AND mandoc~glaccount = items~glaccount
                                                                        AND mandoc~receipt_no = items~receipt_no
                                                                        AND mandoc~physical_operation_date = items~physical_operation_date
     ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
     INTO TABLE @DATA(lt_mandoc_db).

    LOOP AT ms_request-items INTO DATA(ls_item).
      READ TABLE lt_mandoc_db INTO DATA(ls_mandoc_db) WITH KEY companycode = ls_item-companycode
                                                               glaccount = ls_item-glaccount
                                                               receipt_no = ls_item-receipt_no
                                                               physical_operation_date = ls_item-physical_operation_date BINARY SEARCH.
      IF sy-subrc = 0.
        APPEND VALUE #( companycode = ls_item-companycode
                        glaccount = ls_item-glaccount
                        receipt_no = ls_item-receipt_no
                        physical_operation_date = ls_item-physical_operation_date ) TO lt_deleted.
      ELSE.
        APPEND VALUE #( companycode = ls_item-companycode
                        glaccount = ls_item-glaccount
                        receipt_no = ls_item-receipt_no
                        physical_operation_date = ls_item-physical_operation_date
                        accountingdocument = ls_item-accountingdocument
                        fiscalyear = ls_item-fiscalyear
                        createdby = cl_abap_context_info=>get_user_alias( )
                        createddate = cl_abap_context_info=>get_system_date( )
                       ) TO lt_inserted.
      ENDIF.
    ENDLOOP.

    IF lt_deleted IS NOT INITIAL.
      DELETE yeho_t_mandoc FROM TABLE @lt_deleted.
      IF sy-subrc = 0.
        COMMIT WORK AND WAIT.
        MESSAGE ID ycl_eho_utils=>mc_message_class TYPE ycl_eho_utils=>mc_success NUMBER 011  INTO DATA(lv_message).
        APPEND VALUE #( messagetype = ycl_eho_utils=>mc_success message = lv_message ) TO ms_response-messages.
      ENDIF.
    ENDIF.
    IF lt_inserted IS NOT INITIAL.
      INSERT yeho_t_mandoc FROM TABLE @lt_inserted.
      IF sy-subrc = 0.
        COMMIT WORK AND WAIT.
        IF ms_response-messages IS INITIAL.
          MESSAGE ID ycl_eho_utils=>mc_message_class TYPE ycl_eho_utils=>mc_success NUMBER 011  INTO lv_message.
          APPEND VALUE #( messagetype = ycl_eho_utils=>mc_success message = lv_message ) TO ms_response-messages.
        ENDIF.
      ENDIF.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).
  ENDMETHOD.