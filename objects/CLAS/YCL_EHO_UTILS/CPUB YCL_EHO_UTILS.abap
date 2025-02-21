CLASS ycl_eho_utils DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS find_customer_from_tax_number
      IMPORTING iv_tax_number      TYPE i_customer-taxnumber1
      RETURNING VALUE(rv_customer) TYPE kunnr.
    CLASS-METHODS find_supplier_from_tax_number
      IMPORTING iv_tax_number      TYPE i_supplier-taxnumber1
      RETURNING VALUE(rv_supplier) TYPE lifnr.
    CLASS-METHODS find_bp_from_iban
      IMPORTING iv_iban                   TYPE i_businesspartnerbank-iban
      RETURNING VALUE(rv_businesspartner) TYPE i_businesspartnerbank-businesspartner.
    CLASS-METHODS get_bank_name
      IMPORTING iv_bank_code TYPE yeho_e_bank_code
      RETURNING VALUE(rv_bank_name) TYPE banka.
    CLASS-METHODS get_branch_name
      IMPORTING iv_companycode type bukrs
                iv_bank_code type yeho_e_bank_code
                iv_branch_code type yeho_e_branch_code
       RETURNING VALUE(rv_branch_name) type yeho_e_branchnamedescription.
    CONSTANTS mc_message_class TYPE symsgid VALUE 'YEHO_MC'.
    CONSTANTS mc_information TYPE symsgty VALUE 'I'.
    CONSTANTS mc_success TYPE symsgty VALUE 'S'.
    CONSTANTS mc_error TYPE symsgty VALUE 'E'.
    CONSTANTS mc_warning TYPE symsgty VALUE 'W'.