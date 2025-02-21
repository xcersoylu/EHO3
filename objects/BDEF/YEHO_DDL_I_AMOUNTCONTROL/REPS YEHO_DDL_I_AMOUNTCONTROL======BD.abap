managed implementation in class zbp_eho_ddl_i_amountcontrol unique;
strict ( 2 );

define behavior for YEHO_DDL_I_AMOUNTCONTROL //alias <alias_name>
persistent table yeho_t_amounttc
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
//  field ( readonly :update ) Companycode, TransactionCode, DocumentType, Username;
  field ( readonly :update ) Companycode, TransactionCode, DocumentType;
  mapping for yeho_t_amounttc
    {
      Companycode     = companycode;
      TransactionCode = transaction_code;
      DocumentType    = document_type;
//      Username        = username;
    }
}