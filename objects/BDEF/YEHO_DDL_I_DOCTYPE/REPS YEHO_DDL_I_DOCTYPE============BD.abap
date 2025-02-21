managed implementation in class zbp_eho_ddl_i_doctype unique;
strict ( 2 );

define behavior for yeho_ddl_i_doctype //alias <alias_name>
persistent table yeho_t_doctype
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly : update ) Companycode, AccountNo, BankItem, Debitcreditindicator;
  mapping for yeho_t_doctype
    {
      Companycode          = companycode;
      AccountNo            = account_no;
      BankItem             = bank_item;
      Debitcreditindicator = debitcreditindicator;
      Documenttype         = documenttype;
    }
}