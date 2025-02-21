  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareketwthtoken,
              aciklama1   TYPE string,
              aciklama2   TYPE string,
              anahtar     TYPE string,
              bakiye      TYPE string,
              bankakodu   TYPE string,
              bsmv        TYPE string,
              dekontno    TYPE string,
              eftiadeid   TYPE string,
              eftid       TYPE string,
              faiz        TYPE string,
              fisno       TYPE string,
              gecikme     TYPE string,
              gecikmebsmv TYPE string,
              iban        TYPE string,
              islemsaati  TYPE string,
              islemsicil  TYPE string,
              islemsube   TYPE string,
              islemtarihi TYPE string,
              programkod  TYPE string,
              sirano      TYPE string,
              subekodu    TYPE string,
              tip         TYPE string,
              tutar       TYPE string,
              vkntckn     TYPE string,
              valor       TYPE string,
            END OF ty_hareketwthtoken,
            tt_hareketwthtoken TYPE TABLE OF ty_hareketwthtoken WITH EMPTY KEY,
            BEGIN OF ty_hareketler,
              hareketwithtoken TYPE tt_hareketwthtoken,
            END OF ty_hareketler,
            BEGIN OF ty_hesapbilgileri,
              ad                TYPE string,
              bakiye            TYPE string,
              devamivarmi       TYPE string,
              gunacilisbakiye   TYPE string,
              hareketler        TYPE ty_hareketler,
              hesapacilistarihi TYPE string,
              musterino         TYPE string,
              no                TYPE string,
              parakod           TYPE string,
              sonharekettarihi  TYPE string,
              subeadi           TYPE string,
              subekodu          TYPE string,
              tur               TYPE string,
              vkntckn           TYPE string,
            END OF ty_hesapbilgileri.
    DATA ls_json_response   TYPE ty_hesapbilgileri.
    DATA lv_sequence_no     TYPE int4.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    LOOP AT ls_json_response-hareketler-hareketwithtoken ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-amount       = <fs_hareket>-tutar.
      ls_offline_data-description  = <fs_hareket>-aciklama1 && '-' && <fs_hareket>-aciklama2.
      ls_offline_data-debit_credit = <fs_hareket>-tip.
      IF ls_offline_data-debit_credit = 'B'.
        ls_offline_data-payee_vkn = <fs_hareket>-vkntckn.
      ELSEIF ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debtor_vkn = <fs_hareket>-vkntckn.
      ENDIF.
      ls_offline_data-current_balance = <fs_hareket>-bakiye.
      ls_offline_data-receipt_no      = <fs_hareket>-anahtar.
      CONCATENATE <fs_hareket>-islemtarihi+6(4)
                  <fs_hareket>-islemtarihi+3(2)
                  <fs_hareket>-islemtarihi+0(2)
             INTO ls_offline_data-physical_operation_date.
      CONCATENATE <fs_hareket>-islemsaati+0(2)
                  <fs_hareket>-islemsaati+3(2)
                  <fs_hareket>-islemsaati+5(2)
             INTO ls_offline_data-time.
      CONCATENATE <fs_hareket>-valor+6(2)
                  <fs_hareket>-valor+3(2)
                  <fs_hareket>-valor+0(2)
             INTO ls_offline_data-valor.
      ls_offline_data-sender_iban      = <fs_hareket>-iban.
      ls_offline_data-transaction_type = <fs_hareket>-programkod+0(3).
      ls_offline_data-sender_branch    = <fs_hareket>-islemsube.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
    IF sy-subrc = 0.
      DATA(lt_bank_data) = et_bank_data.
      SORT lt_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
      IF ls_bank_data-debit_credit = 'B'.
        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
      ELSE.
        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
      ENDIF.
      SORT lt_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
      lv_closing_balance = ls_bank_data-current_balance.
    ELSE.
      lv_opening_balance  = lv_closing_balance = ls_json_response-gunacilisbakiye.
    ENDIF.

    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount   = ms_bankpass-glaccount
                    valid_from  = mv_startdate
                    account_no  = ms_bankpass-bankaccount
                    branch_no   = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  lv_opening_balance
                    closing_balance =  lv_closing_balance
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.
  ENDMETHOD.