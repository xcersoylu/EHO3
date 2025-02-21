  METHOD mapping_bank_data.
    TYPES:
      BEGIN OF mty_detail.
    TYPES valortarihi          TYPE string.
    TYPES islemtarihi          TYPE string.
    TYPES referansno           TYPE string.
    TYPES karsihesapiban       TYPE string.
    TYPES tutar                TYPE string.
    TYPES sonbakiye            TYPE string.
    TYPES aciklama             TYPE string.
    TYPES vkn                  TYPE string.
    TYPES tutarborcalacak      TYPE string.
    TYPES sonbakiyeborcalacak  TYPE string.
    TYPES fonksiyonkodu        TYPE string.
    TYPES mt940fonksiyonkodu   TYPE string.
    TYPES fisno                TYPE string.
    TYPES ozelalan1            TYPE string.
    TYPES ozelalan2            TYPE string.
    TYPES aboneno              TYPE string.
    TYPES faturano             TYPE string.
    TYPES faturadonem          TYPE string.
    TYPES faturasonodemetarihi TYPE string.
    TYPES lehdarvkn            TYPE string.
    TYPES lehdartckn           TYPE string.
    TYPES amirvkn              TYPE string.
    TYPES amirtckn             TYPE string.
    TYPES borcluiban           TYPE string.
    TYPES alacakliiban         TYPE string.
    TYPES dekontborcaciklama   TYPE string.
    TYPES dekontalacakaciklama TYPE string.
    TYPES islemiyapansube      TYPE string.
    TYPES hareketdurumu        TYPE string.
    TYPES timestamp            TYPE string.
    TYPES END OF mty_detail .
    TYPES:
      BEGIN OF mty_hesap.
    TYPES sqlid                    TYPE string.
    TYPES hesapturuadi             TYPE string.
    TYPES hesapno                  TYPE string.
    TYPES urf                      TYPE string.
    TYPES subekodu                 TYPE string.
    TYPES subeadi                  TYPE string.
    TYPES dovizkodu                TYPE string.
    TYPES iban                     TYPE string.
    TYPES acilisilkbakiye          TYPE string.
    TYPES acilisgunbakiye          TYPE string.
    TYPES caribakiye               TYPE string.
    TYPES bakiye                   TYPE string.
    TYPES blokemeblag              TYPE string.
    TYPES hesapacilistarihi        TYPE string.
    TYPES sonharekettarihi         TYPE string.
    TYPES hesapturukodu            TYPE string.
    TYPES lasttmst                 TYPE string.
    TYPES aktifflag                TYPE string.
    TYPES detayflag                TYPE string.
    TYPES dekontbilgiflag          TYPE string.
    TYPES vadelihareketlerislensin TYPE string.
    TYPES detay                    TYPE TABLE OF mty_detail WITH DEFAULT KEY.
    TYPES END OF mty_hesap .
    TYPES:
      BEGIN OF mty_json.
    TYPES hesaphareketleriresult TYPE TABLE OF mty_hesap WITH DEFAULT KEY.
    TYPES END OF mty_json .
    DATA ls_json_response TYPE mty_json.
    DATA lv_json TYPE string.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_doviz_kod TYPE string.
    lv_json = iv_json.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    IF ms_bankpass-currency EQ 'TRY' OR ms_bankpass-currency EQ 'TRL'.
      lv_doviz_kod = 'YTL'.
    ELSE.
      lv_doviz_kod = ms_bankpass-currency.
    ENDIF.

    READ TABLE ls_json_response-hesaphareketleriresult INTO DATA(ls_hesap) WITH KEY dovizkodu = lv_doviz_kod.

*    ls_list-acilis_bakiyesi = ls_hesap-acilisgunbakiye.

    LOOP AT ls_hesap-detay INTO DATA(ls_detay).
*      ls_list-kapanis_bakiyesi = ls_detay-sonbakiye.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.


      ls_offline_data-amount = ls_detay-tutar.

      ls_offline_data-description = ls_detay-aciklama.

      IF ls_detay-dekontalacakaciklama IS NOT INITIAL AND ls_detay-dekontborcaciklama IS NOT INITIAL.

        CONCATENATE ls_offline_data-description
                    ls_detay-dekontalacakaciklama
                    ls_detay-dekontborcaciklama
                    INTO ls_offline_data-description SEPARATED BY space.

      ELSEIF ls_detay-dekontalacakaciklama IS NOT INITIAL.

        CONCATENATE ls_offline_data-description
                    ls_detay-dekontalacakaciklama
                    INTO ls_offline_data-description SEPARATED BY space.

      ELSEIF ls_detay-dekontborcaciklama IS NOT INITIAL.

        CONCATENATE ls_offline_data-description
                    ls_detay-dekontborcaciklama
                    INTO ls_offline_data-description SEPARATED BY space.

      ENDIF.

      IF ls_detay-tutarborcalacak EQ '+'.
        ls_offline_data-debtor_vkn = ls_detay-vkn.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-borcluiban.
      ELSEIF ls_detay-tutarborcalacak EQ '-'.
        ls_offline_data-payee_vkn = ls_detay-vkn.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban      = ls_detay-alacakliiban.
      ENDIF.

      ls_offline_data-additional_field1                = ls_detay-ozelalan1.
      ls_offline_data-additional_field2                = ls_detay-ozelalan2.
      ls_offline_data-current_balance          = ls_detay-sonbakiye.
      ls_offline_data-receipt_no             = ls_detay-fisno.
      ls_offline_data-physical_operation_date = ls_detay-islemtarihi.
      ls_offline_data-valor                 = ls_detay-valortarihi.
      ls_offline_data-sender_branch         = ls_detay-islemiyapansube.
      ls_offline_data-transaction_type            = ls_detay-mt940fonksiyonkodu.

      IF strlen( ls_detay-timestamp ) GE 14.
        ls_offline_data-time = ls_detay-timestamp+8(6).
      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.

    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount = ms_bankpass-glaccount
                    valid_from = mv_startdate
                    account_no = ms_bankpass-bankaccount
                    branch_no = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  ls_hesap-acilisgunbakiye
                    closing_balance = ls_detay-sonbakiye
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.