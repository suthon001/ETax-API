/// <summary>
/// Report Etax Select Header Invoice (ID 80203).
/// </summary>
report 80203 "Etax Select Header Invoice"
{
    Caption = 'Select Header Invoice';
    ProcessingOnly = true;
    UsageCategory = None;
    dataset
    {
        dataitem(SalesInvoiceHeader; "Sales Invoice Header")
        {
            trigger OnAfterGetRecord()
            var
                EtaxFunc: Codeunit "NCT ETaxFunc";
            begin
                if EtaxType = EtaxType::" " then
                    error('Please Select Etax Type');

                EtaxFunc.ETaxSalesInvoice(SalesInvoiceHeader, EtaxType);
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                field(EtaxType; EtaxType)
                {
                    Caption = 'Etax Type';
                    ApplicationArea = all;
                    ValuesAllowed = 0, 2, 3, 4;
                    ToolTip = 'Specifies the value of the Etax Type field.';
                }
            }
        }

    }
    var
        EtaxType: Enum "NCT Etax Type";
}
