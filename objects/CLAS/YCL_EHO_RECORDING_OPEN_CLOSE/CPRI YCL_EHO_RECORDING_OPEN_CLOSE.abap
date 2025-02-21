  PRIVATE SECTION.
    DATA: ms_request  TYPE yeho_s_open_close_req,
          ms_response TYPE yeho_s_open_close_res.
    CONSTANTS: mc_header_content TYPE string VALUE 'content-type',
               mc_content_type   TYPE string VALUE 'text/json'.