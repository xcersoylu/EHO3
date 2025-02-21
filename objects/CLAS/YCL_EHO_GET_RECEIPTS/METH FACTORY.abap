  METHOD factory.
    IF is_bankpass IS INITIAL.
    ELSE.
      DATA(lv_class_name) = mc_class_name && is_bankpass-class_suffix.
      CREATE OBJECT ro_object TYPE (lv_class_name).
      ro_object->ms_bankpass = is_bankpass.
      ro_object->mv_startdate = iv_startdate.
      ro_object->mv_enddate = iv_enddate.
    ENDIF.
  ENDMETHOD.