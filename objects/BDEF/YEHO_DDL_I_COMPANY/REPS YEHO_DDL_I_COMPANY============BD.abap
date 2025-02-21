managed implementation in class zbp_eho_ddl_i_company unique;
strict ( 2 );

define behavior for YEHO_DDL_I_COMPANY //alias <alias_name>
persistent table yeho_t_company
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly :update ) Companycode;
  mapping for yeho_t_company
    {
      Companycode      = companycode;
      TaxNumber        = tax_number;
      ArbitrageAccount = arbitrage_account;
      StartDate        = start_date;
      CurrencyField    = currency_field;
      Email            = email;
    }
}