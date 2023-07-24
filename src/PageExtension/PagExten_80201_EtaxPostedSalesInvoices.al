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
                Caption = 'E-tax';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Etax action.';
                trigger OnAction()
                var
                    EtaxFunc: Codeunit "NCT ETaxFunc";
                    SalesInvoice: record "Sales Invoice Header";
                begin

                    SalesInvoice.Copy(rec);
                    CurrPage.SetSelectionFilter(SalesInvoice);
                    SalesInvoice.SetRange("NCT Etax Send to E-Tax", false);
                    SalesInvoice.SetFilter(Amount, '<>%1', 0);
                    if not confirm(StrSubstNo('Do you want Send to E-tax %1 record', SalesInvoice.Count)) then
                        exit;
                    if SalesInvoice.FindSet() then
                        repeat
                            EtaxFunc.ETaxSalesInvoice(SalesInvoice);
                        until SalesInvoice.Next() = 0;
                end;
            }
            action(EtaxLog)
            {
                ApplicationArea = all;
                Caption = 'E-tax (Log)';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Etax (Log) action.';
                trigger OnAction()
                var
                    EtaxLog: Record "NCT Etax Log";
                    EtaxLogEntry: Page "NCT Etax Log Entry";
                begin
                    CLEAR(EtaxLogEntry);
                    EtaxLog.reset();
                    EtaxLog.SetRange("Document Type", EtaxLog."Document Type"::"Sales Invoice");
                    EtaxLog.SetRange("Document No.", rec."No.");
                    EtaxLogEntry.SetTableView(EtaxLog);
                    EtaxLogEntry.Run();
                    CLEAR(EtaxLogEntry);
                end;
            }
        }
    }
}
