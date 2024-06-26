/// <summary>
/// PageExtension NCT Etax Sales Receipt Card (ID 80208) extends Record NCT Sales Receipt Card.
/// </summary>
pageextension 80208 "NCT Etax Sales Receipt Card" extends "NCT Sales Receipt Card"
{
    layout
    {
        addafter(SalesBillingLine)
        {
            group(ETaxInformation)
            {
                Caption = 'E-Tax Information';
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
    }
    actions
    {
        addfirst(processing)
        {
            action(SendEtax)
            {
                ApplicationArea = all;
                Caption = 'Send E-tax';
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
                    rec.TestField(Status, rec.Status::Posted);
                    if not confirm(StrSubstNo('Do you want Send Document No. %1 to E-tax', rec."No.")) then
                        exit;
                    EtaxFunc.ETaxSalesReceip(rec);
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
                    EtaxLog.SetRange("Document Type", EtaxLog."Document Type"::"Sales Receipt");
                    EtaxLog.SetRange("Document No.", rec."No.");
                    EtaxLogEntry.SetTableView(EtaxLog);
                    EtaxLogEntry.Run();
                    CLEAR(EtaxLogEntry);
                end;
            }
        }
    }

}
