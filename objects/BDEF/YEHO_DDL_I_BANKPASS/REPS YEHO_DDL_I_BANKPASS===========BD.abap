managed implementation in class zbp_eho_ddl_i_bankpass unique;
strict ( 2 );

define behavior for yeho_ddl_I_Bankpass //alias <alias_name>
persistent table yeho_t_bankpass
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly : update ) Companycode, Glaccount, Currency, Bankaccount;
  mapping for yeho_t_bankpass
  {
    Companycode      = companycode;
    Glaccount        = glaccount;
    Currency         = currency;
    Bankaccount      = bankaccount;
    Iban             = iban ;
    BankCode         = bank_code ;
    BranchCode       = branch_code ;
    FirmCode         = firm_code ;
    ServiceUser      = service_user ;
    ServicePassword  = service_password ;
    OwnerTitle       = owner_title  ;
    OwnerDescription = owner_description;
    Suffix           = suffix;
    ConnectionType   = connection_type ;
    RfcDestination   = rfc_destination ;
    ServiceUrl       = service_url  ;
    NamespaceUrl     = namespace_url;
    ClassSuffix      = class_suffix ;
    CpiUser          = cpi_user    ;
    CpiPassword      = cpi_password;
    CpiUrl           = cpi_url       ;
    AdditionalField1 = additional_field1;
    AdditionalField2 = additional_field2;
    AdditionalField3 = additional_field3;
   }
}