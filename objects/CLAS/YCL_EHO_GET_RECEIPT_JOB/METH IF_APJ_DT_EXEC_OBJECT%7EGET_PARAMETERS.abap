  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #( ( selname = 'P_CCODE'
                                  kind = if_apj_dt_exec_object=>parameter
                                  datatype = 'C'
                                  length = 4
                                  param_text = 'Şirket Kodu'
                                  changeable_ind = abap_true )
                                ( selname = 'S_GLACC'
                                  kind = if_apj_dt_exec_object=>select_option
                                  datatype = 'C'
                                  length = 10
                                  param_text = 'Hesap No'
                                  changeable_ind = abap_true )
                                ( selname = 'P_STARTD'
                                  kind = if_apj_dt_exec_object=>parameter
                                  datatype = 'D'
                                  length = 8
                                  param_text = 'Başlangıç Tarihi'
                                  changeable_ind = abap_true )
                                ( selname = 'P_ENDD'
                                  kind = if_apj_dt_exec_object=>parameter
                                  datatype = 'D'
                                  length = 8
                                  param_text = 'Bitiş Tarihi'
                                  changeable_ind = abap_true )
                               ).
  ENDMETHOD.