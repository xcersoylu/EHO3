  PRIVATE SECTION.
    DATA: ms_request  TYPE yeho_s_delete_rule_req,
          ms_response TYPE yeho_s_delete_rule_res.
    CONSTANTS: mc_header_content TYPE string VALUE 'content-type',
               mc_content_type   TYPE string VALUE 'text/json'.