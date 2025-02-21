managed implementation in class zbp_eho_ddl_i_exchangetype unique;
strict ( 2 );

define behavior for yeho_ddl_i_exchangetype //alias <alias_name>
persistent table yeho_t_exchtype
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly : update ) Companycode, Salesorganization, Distributionchannel, Division;
  mapping for yeho_t_exchtype
    {
      Companycode         = companycode;
      Salesorganization   = salesorganization;
      Distributionchannel = distributionchannel;
      Division            = division;
      Exchangeratetype    = exchangeratetype;
    }
}