  METHOD fill_json.
    DATA(lv_begindate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) && 'T00:00:00'.

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2) && 'T23:59:59'.

    rv_json = '{' &&
              |"associationCode":"{ ms_bankpass-firm_code } | & |", | &
              |"startDate":"{ lv_begindate } | & | ", | &
              |"endDate":"{ lv_begindate } | && '"}'.
  ENDMETHOD.