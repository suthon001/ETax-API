/// <summary>
/// PageExtension NCT Etax Sales Receipt List (ID 80207) extends Record NCT Sales Receipt List.
/// </summary>
pageextension 80207 "NCT Etax Sales Receipt List" extends "NCT Sales Receipt List"
{
    layout
    {
        addlast(General)
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
            field("Have Email"; rec."Have Email")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the Have Email field.';
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
                Caption = 'Send E-tax';
                Image = SendElectronicDocument;
                ToolTip = 'Executes the Etax action.';
                trigger OnAction()
                var
                    //  EtaxFunc: Codeunit "NCT ETaxFunc";
                    SalesReceipt: record "NCT Billing Receipt Header";

                begin

                    // SalesReceipt.Copy(rec);
                    // CurrPage.SetSelectionFilter(SalesReceipt);
                    // SalesReceipt.SetRange("NCT Etax Send to E-Tax", false);
                    // SalesReceipt.SetRange(Status, SalesReceipt.Status::Posted);
                    // SalesReceipt.SetFilter(Amount, '<>%1', 0);
                    // if not confirm(StrSubstNo('Do you want Send to E-tax %1 record', SalesReceipt.Count)) then
                    //     exit;
                    // EtaxFunc.ETaxSalesReceip(SalesReceipt);
                    rec.TestField(Status, rec.Status::Posted);
                    rec.TestField("NCT Etax Send to E-Tax", false);
                    SalesReceipt.reset();
                    SalesReceipt.SetRange("No.", rec."No.");
                    REPORT.RUNMODAL(REPORT::"Etax Select Header Receipt", TRUE, FALSE, SalesReceipt);
                end;
            }
            action(EtaxLog)
            {
                ApplicationArea = all;
                Caption = 'E-tax (Log)';
                Image = SendElectronicDocument;

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
        modify(Category_Category18)
        {
            Caption = 'E-Tax';
        }
        addfirst(Category_Category18)
        {

            actionref(SendEtax_Promoted; SendEtax)
            {
            }
            actionref(EtaxLog_Promoted; EtaxLog)
            {
            }
        }
    }
}
