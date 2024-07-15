/// <summary>
/// Report Etax Select Header Receipt (ID 80204).
/// </summary>
report 80204 "Etax Select Header Receipt"
{
    Caption = 'Select Header Receipt';
    ProcessingOnly = true;
    UsageCategory = None;
    dataset
    {
        dataitem("NCT Billing Receipt Header"; "NCT Billing Receipt Header")
        {
            trigger OnAfterGetRecord()
            var
                EtaxFunc: Codeunit "NCT ETaxFunc";
            begin
                if EtaxType = EtaxType::" " then
                    error('Please Select Etax Type');

                EtaxFunc.ETaxSalesReceip("NCT Billing Receipt Header", EtaxType);
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
                    ValuesAllowed = 0, 3, 5;
                    ToolTip = 'Specifies the value of the Etax Type field.';
                }
            }
        }

    }
    var
        EtaxType: Enum "NCT Etax Type";
}
