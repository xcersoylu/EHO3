managed implementation in class zbp_eho_ddl_i_otoexc unique;
strict ( 2 );

define behavior for YEHO_DDL_I_OTOEXC //alias <alias_name>
persistent table yeho_t_otoexc
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly : update ) Companycode, TransactionType, TaxNumber, Customer, Supplier;
  mapping for yeho_t_otoexc
    {
      Companycode     = companycode;
      TransactionType = transaction_type;
      TaxNumber       = tax_number;
      Customer        = customer;
      Supplier        = supplier;
    }
}