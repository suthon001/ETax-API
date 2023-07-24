/// <summary>
/// PageExtension NCT Etax Posted Sales Invoices (ID 80201) extends Record Posted Sales Invoices.
/// </summary>
pageextension 80201 "NCT Etax Posted Sales Invoices" extends "Posted Sales Invoices"
{
    actions
    {
        addfirst(processing)
        {
            action(SendEtax)
            {
                ApplicationArea = all;
                Caption = 'Etax';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Etax action.';
                trigger OnAction()
                var
                    EtaxFunc: Codeunit "NCT ETaxFunc";
                begin
                    EtaxFunc.ETaxSalesInvoice(rec);
                end;
            }
        }
    }
}
