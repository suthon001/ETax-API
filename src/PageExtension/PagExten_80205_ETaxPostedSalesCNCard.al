/// <summary>
/// PageExtension NCT ETax Posted Sales CN Card (ID 80205) extends Record Posted Sales Credit Memo.
/// </summary>
pageextension 80205 "NCT ETax Posted Sales CN Card" extends "Posted Sales Credit Memo"
{
    layout
    {
        addafter(SalesCrMemoLines)
        {
            group(ETaxInformation)
            {
                Caption = 'E-Tax Information';
                field("NCT Etax Purpose"; rec."NCT Etax Purpose")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the E-Tax Purpose field.';
                }
                field("NCT Etax Purpose Remark"; rec."NCT Etax Purpose Remark")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the E-Tax Purpose Remark field.';
                }
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
                    EtaxFunc: Codeunit "NCT ETaxFunc";
                    EtaxType: Enum "NCT Etax Type";
                begin
                    rec.TestField("NCT Etax Send to E-Tax", false);
                    if not confirm(StrSubstNo('Do you want Send Document No. %1 to E-tax', rec."No.")) then
                        exit;
                    EtaxFunc.ETaxSalesCreditMemo(rec, EtaxType::"81");
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
                    EtaxLog.SetRange("Document Type", EtaxLog."Document Type"::"Sales Credit Memo");
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
