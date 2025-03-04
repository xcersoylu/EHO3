  METHOD if_apj_rt_exec_object~execute.
    DATA lv_startdate        TYPE datum.
    DATA lv_enddate          TYPE datum.
    DATA lt_bank_data        TYPE yeho_tt_offline_bank_data.
    DATA lt_bank_balance     TYPE yeho_tt_offlinebd.
    DATA lt_bank_data_all    TYPE yeho_tt_offline_bank_data.
    DATA lt_bank_balance_all TYPE yeho_tt_offlinebd.
    DATA lv_original_data    TYPE string.
    DATA lt_glaccount_range TYPE RANGE OF hkont.
    DATA lv_error TYPE abap_boolean.
    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'P_COMPANYCODE'.
          DATA(lv_companycode) = CONV bukrs( ls_parameter-low ).
        WHEN 'S_GLACCOUNT'.
          APPEND INITIAL LINE TO lt_glaccount_range ASSIGNING FIELD-SYMBOL(<ls_glaccount_range>).
          <ls_glaccount_range> = CORRESPONDING #( ls_parameter ).
        WHEN 'P_STARTDATE'.
          lv_startdate = COND #( WHEN ls_parameter-low IS INITIAL THEN cl_abap_context_info=>get_system_date(  ) ELSE ls_parameter-low ).
        WHEN 'P_ENDDATE'.
          lv_enddate = COND #( WHEN ls_parameter-low IS INITIAL THEN cl_abap_context_info=>get_system_date(  ) ELSE ls_parameter-low ).
      ENDCASE.
    ENDLOOP.
    TRY.
        DATA(lo_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object = 'YEHO_APP_LOG'
                                                                                       subobject = 'GET_RECEIPT_JOB' ) ).

        IF lv_companycode IS INITIAL.
          lv_error = abap_true.
          DATA(lo_message) = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                             id = ycl_eho_utils=>mc_message_class
                                                             number = '002' ).
          lo_log->add_item( lo_message ).
        ENDIF.
        IF lv_enddate IS NOT INITIAL AND lv_enddate < lv_startdate.
          lv_error = abap_true.
          lo_message = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                             id = ycl_eho_utils=>mc_message_class
                                                             number = '003' ).
          lo_log->add_item( lo_message ).
        ENDIF.
        IF lv_startdate < cl_abap_context_info=>get_system_date(  ).
          lv_error = abap_true.
          lo_message = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                             id = ycl_eho_utils=>mc_message_class
                                                             number = '004' ).
          lo_log->add_item( lo_message ).
        ENDIF.
        SELECT * FROM yeho_t_bankpass
                 WHERE companycode = @lv_companycode
                   AND glaccount IN @lt_glaccount_range
                   INTO TABLE @DATA(lt_bankpass).
        IF sy-subrc <> 0.
          lv_error = abap_true.
          lo_message = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                             id = ycl_eho_utils=>mc_message_class
                                                             number = '005' ).
          lo_log->add_item( lo_message ).
        ENDIF.
        SELECT housebank~companycode , housebank~glaccount , housebank~bankname,housebank~bankaccountdescription
        FROM @lt_bankpass AS bankpass INNER JOIN i_housebankaccountlinkage AS housebank ON housebank~companycode = bankpass~companycode
                                                                                       AND housebank~glaccount = bankpass~glaccount
        INTO TABLE @DATA(lt_bank_info).

        IF lv_error IS INITIAL.
          DO.
            IF lv_enddate < lv_startdate.
              EXIT.
            ENDIF.
            LOOP AT lt_bankpass INTO DATA(ls_bankpass).
              CLEAR : lt_bank_data , lt_bank_balance , lv_original_data.
              ycl_eho_get_receipts=>factory(
                EXPORTING
                  is_bankpass = ls_bankpass
                  iv_startdate = lv_startdate
                  iv_enddate = lv_enddate
                RECEIVING
                  ro_object   = DATA(lo_object)
              ).
              lo_object->call_api(
                IMPORTING
                  et_bank_data = lt_bank_data
                  et_bank_balance = lt_bank_balance
                  ev_original_data = lv_original_data
              ).
              IF lt_bank_data IS NOT INITIAL OR lt_bank_balance IS NOT INITIAL.
                APPEND LINES OF lt_bank_data TO lt_bank_data_all.
                APPEND LINES OF lt_bank_balance TO lt_bank_balance_all.
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
        cl_bali_log_db=>get_instance( )->save_log( log = lo_log assign_to_current_appl_job = abap_true ).
      CATCH cx_bali_runtime.
    ENDTRY.
  ENDMETHOD.