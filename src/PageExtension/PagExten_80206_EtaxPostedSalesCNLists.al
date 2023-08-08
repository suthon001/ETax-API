/// <summary>
/// PageExtension NCT Etax Posted Sales CN Lists (ID 80206) extends Record Posted Sales Credit Memos.
/// </summary>
pageextension 80206 "NCT Etax Posted Sales CN Lists" extends "Posted Sales Credit Memos"
{
    layout
    {
        addlast(Control1)
        {
            field("NCT Etax Send to E-Tax"; rec."NCT Etax Send to E-Tax")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the E-tax Send to E-Tax field.';
            }
            field("NCT Etax Status"; rec."NCT Etax Status")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the E-tax Status field.';
            }
            field("NCT Etax No. of Send"; rec."NCT Etax No. of Send")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the E-tax No. of Send field.';
            }
            field("NCT Etax Last File Name"; rec."NCT Etax Last File Name")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the E-tax Last File Name field.';
            }
            field("NCT Etax Send By"; rec."NCT Etax Send By")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the E-tax Send By field.';
            }
            field("NCT Etax Send DateTime"; rec."NCT Etax Send DateTime")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the E-tax Send DateTime field.';
            }
        }
    }
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
                    SalesCreditMemo: record "Sales Cr.Memo Header";

                begin

                    SalesCreditMemo.Copy(rec);
                    CurrPage.SetSelectionFilter(SalesCreditMemo);
                    SalesCreditMemo.SetRange("NCT Etax Send to E-Tax", false);
                    SalesCreditMemo.SetFilter(Amount, '<>%1', 0);
                    if not confirm(StrSubstNo('Do you want Send to E-tax %1 record', SalesCreditMemo.Count)) then
                        exit;
                    EtaxFunc.ETaxSalesCreditMemo(SalesCreditMemo);
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
                    EtaxLog.SetRange("Document Type", EtaxLog."Document Type"::"Sales Credit Memo");
                    EtaxLog.SetRange("Document No.", rec."No.");
                    EtaxLogEntry.SetTableView(EtaxLog);
                    EtaxLogEntry.Run();
                    CLEAR(EtaxLogEntry);
                end;
            }
        }
    }
}

