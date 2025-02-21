managed implementation in class zbp_eho_ddl_i_currencychange unique;
strict ( 2 );

define behavior for YEHO_DDL_I_CURRENCYCHANGE //alias <alias_name>
persistent table yeho_t_currchng
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly : update ) Customer, Attribute1, Currency, Currency2;
  mapping for yeho_t_currchng
    {
      Customer   = customer;
      Attribute1 = attribute1;
      Currency   = currency;
      Currency2  = currency2;
    }

}