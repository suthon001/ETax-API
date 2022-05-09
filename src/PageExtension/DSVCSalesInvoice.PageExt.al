/// <summary>
/// PageExtension DSVC SalesInvoice (ID 70200) extends Record Sales Invoice.
/// </summary>
pageextension 70200 "DSVC SalesInvoice" extends "Sales Invoice"
{
    PromotedActionCategories = 'New,Process,Report,Approve,Posting,Prepare,Invoice,Release,Request Approval,View,Navigate,E-Tax';
    actions
    {
        addlast(processing)
        {
            action(DSVCETax)
            {
                ApplicationArea = all;
                Image = SendEmailPDF;
                Caption = 'E-Tax';
                ToolTip = 'Send Etax';
                PromotedCategory = Category12;
                Promoted = true;
                trigger OnAction()
                var
                    DSVCExtaxFunctions: Codeunit DSVCEtaxFunctions;
                begin
                    DSVCExtaxFunctions.DSVCWriteText(rec);
                end;
            }
        }
    }
}