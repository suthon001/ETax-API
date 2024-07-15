/// <summary>
/// PageExtension NCT Etax Posted Sales Invoices (ID 80201) extends Record Posted Sales Invoices.
/// </summary>
pageextension 80201 "NCT Etax Posted Sales Invoices" extends "Posted Sales Invoices"
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
                Caption = 'Send E-tax';
                Image = SendElectronicDocument;
                ToolTip = 'Executes the Etax action.';
                trigger OnAction()
                var
                    //   EtaxFunc: Codeunit "NCT ETaxFunc";
                    SalesInvoice: record "Sales Invoice Header";

                begin

                    // SalesInvoice.Copy(rec);
                    // CurrPage.SetSelectionFilter(SalesInvoice);
                    // SalesInvoice.SetRange("NCT Etax Send to E-Tax", false);
                    // SalesInvoice.SetFilter(Amount, '<>%1', 0);
                    // if not confirm(StrSubstNo('Do you want Send to E-tax %1 record', SalesInvoice.Count)) then
                    //     exit;
                    // EtaxFunc.ETaxSalesInvoice(SalesInvoice);
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

