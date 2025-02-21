  METHOD fill_json.
    DATA :
      lv_account_suffix TYPE string,
      lv_crid           TYPE c LENGTH 19,
      lv_csid           TYPE c LENGTH 32.

    DATA(lv_begindate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) && 'T00:00:00.000+03:00'.

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2) && 'T23:59:59.000+03:00'.

    CONCATENATE mv_startdate 'T00:00:00' INTO mv_startdate.
    CONCATENATE mv_enddate 'T23:59:59' INTO mv_enddate.

*    CALL FUNCTION 'RSEC_GENERATE_PASSWORD'
*      EXPORTING
*        alphabet        = '0123456789ABCDEF'
*        alphabet_length = 16
*        output_length   = 32
*      IMPORTING
*        output          = lv_csid
*      EXCEPTIONS
*        some_error      = 1
*        OTHERS          = 2.
*
*    CALL FUNCTION 'RSEC_GENERATE_PASSWORD'
*      EXPORTING
*        alphabet        = '0123456789'
*        alphabet_length = 10
*        output_length   = 19
*      IMPORTING
*        output          = lv_crid
*      EXCEPTIONS
*        some_error      = 1
*        OTHERS          = 2.

    TRANSLATE lv_csid TO LOWER CASE.
    TRANSLATE lv_crid TO LOWER CASE.

    IF ms_bankpass-suffix IS NOT INITIAL.
      CONCATENATE
      '"AccountSuffix": "' ms_bankpass-suffix '",'
      INTO lv_account_suffix.
    ENDIF.

    CONCATENATE
    '{'
    '"Header":{'
    '"AppKey": "' ms_bankpass-service_password '",'
    '"Channel": "' ms_bankpass-service_user '",'
    '"ChannelSessionId": "' lv_csid '",'
    '"ChannelRequestId": "' lv_crid '"'
    '},'
    '"Parameters":['
    '{'
    '"CustomerNo":"' ms_bankpass-firm_code '",'
    '"AccountBranchCode": "' ms_bankpass-branch_code '",'
    lv_account_suffix
    '"AssociationCode": "' ms_bankpass-bank_code  '",'
    '"IBANNo": "' ms_bankpass-iban '",'
    '"QueryDate": "' lv_begindate '",'
    '"EndDate": "' lv_enddate '"'
    '}'
    ']'
    '}'
    INTO rv_json.
  ENDMETHOD.