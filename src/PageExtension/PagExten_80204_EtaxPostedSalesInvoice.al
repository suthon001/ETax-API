/// <summary>
/// PageExtension NCT Etax Posted Sales Invoice (ID 80204) extends Record Posted Sales Invoice.
/// </summary>
pageextension 80204 "NCT Etax Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        addafter(SalesInvLines)
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

                ToolTip = 'Executes the Etax action.';
                trigger OnAction()
                var
                    SalesInvoice: Record "Sales Invoice Header";
                begin
                    rec.TestField("NCT Etax Send to E-Tax", false);
                    SalesInvoice.reset();
                    SalesInvoice.SetRange("No.", rec."No.");
                    REPORT.RUNMODAL(REPORT::"Etax Select Header Invoice", TRUE, FALSE, SalesInvoice);
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
                    EtaxLog.SetRange("Document Type", EtaxLog."Document Type"::"Sales Invoice");
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
