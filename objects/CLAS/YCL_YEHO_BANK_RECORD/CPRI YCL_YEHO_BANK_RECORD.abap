  PRIVATE SECTION.
    DATA: ms_request  TYPE yeho_s_bank_record_req,
          ms_response TYPE yeho_s_bank_record_res.
    METHODS get_rule_data
      IMPORTING
        iv_rule_no       TYPE posnr
      RETURNING
        VALUE(rs_result) TYPE yeho_s_rule_data.
    CONSTANTS: mc_header_content TYPE string VALUE 'content-type',
               mc_content_type   TYPE string VALUE 'text/json'.