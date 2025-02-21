managed implementation in class zbp_eho_ddl_i_rules unique;
strict ( 2 );

define behavior for YEHO_DDL_I_RULES //alias <alias_name>
persistent table yeho_t_rules
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly :update ) Companycode, Itemno;
  mapping for yeho_t_rules
    {
      Companycode                   = companycode;
      Itemno                        = itemno;
      AccountNo102                  = account_no_102;
      TransactionType               = transaction_type;
      TaxNumber                     = tax_number;
      Iban                          = iban;
      Documentitemtext              = documentitemtext;
      DebitCreditIndicator          = debit_credit_indicator;
      DocumentType                  = document_type;
      Specialglcode                 = specialglcode;
      Customer                      = customer;
      Supplier                      = supplier;
      AccountNo                     = account_no;
      ArbitrageAccountNo            = arbitrage_account_no;
      Currency                      = currency;
      Documentitemtext1             = documentitemtext_1;
      Documentitemtext2             = documentitemtext_2;
      Documentreferenceid           = documentreferenceid;
      Accountingdocumentheadertext  = accountingdocumentheadertext;
      Assignmentreference           = assignmentreference;
      Paymentmethod                 = paymentmethod;
      Paymentterms                  = paymentterms;
//      Creditcontrolarea             = creditcontrolarea;
      Costcenter                    = costcenter;
      Orderid                       = orderid;
      Profitcenter                  = profitcenter;
      Wbselementinternalid          = wbselementinternalid;
      Personnelnumber               = personnelnumber;
      Reference1idbybusinesspartner = reference1idbybusinesspartner;
      Reference2idbybusinesspartner = reference2idbybusinesspartner;
      Reference3idbybusinesspartner = reference3idbybusinesspartner;
      Taxcode                       = taxcode;
      Businessplace                 = businessplace;
    }
}