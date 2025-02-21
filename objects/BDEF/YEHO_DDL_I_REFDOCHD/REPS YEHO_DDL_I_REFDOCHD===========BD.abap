managed implementation in class zbp_eho_ddl_i_refdochd unique;
strict ( 2 );

define behavior for yeho_ddl_i_REFDOCHD //alias <alias_name>
persistent table yeho_t_refdochd
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly : update ) Companycode, AccountNo, DocumentType;
  mapping for yeho_t_refdochd
    {
      Companycode            = companycode;
      AccountNo              = account_no;
      DocumentType           = document_type;
      ReferenceDocumentFlag  = reference_document_flag;
      DocumentHeaderTextFlag = document_header_text_flag;
    }
}