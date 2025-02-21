  PRIVATE SECTION.
    DATA: ms_request  TYPE yeho_s_bank_api_req,
          ms_response TYPE yeho_s_bank_api_res.
    CONSTANTS: mc_header_content TYPE string VALUE 'content-type',
               mc_content_type   TYPE string VALUE 'text/json'.