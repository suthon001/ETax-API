/// <summary>
/// PageExtension NCT Etax Sales Setup (ID 80202) extends Record Sales Receivables Setup.
/// </summary>
pageextension 80202 "NCT Etax Sales Setup" extends "Sales & Receivables Setup"
{
    layout
    {
        addafter(General)
        {
            group(EtaxInformation)
            {
                Caption = 'E-Tax Information';
                field("NCT Etax User Code"; rec."NCT Etax User Code")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the User Code field.';
                }
                field("NCT Etax API Key"; rec."NCT Etax API Key")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the API Key field.';
                }
                field("NCT Etax Access Key"; rec."NCT Etax Access Key")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Access Key field.';
                }
                field("NCT Etax Service Code"; rec."NCT Etax Service Code")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Service Code field.';
                }
                field("NCT Etax Seller Tax ID"; rec."NCT Etax Seller Tax ID")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Seller Tax ID field.';
                }
                field("NCT Etax Seller Branch ID"; rec."NCT Etax Seller Branch ID")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Seller Branch ID field.';
                }
                field("NCT Etax Service URL"; rec."NCT Etax Service URL")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Service URL field.';
                }
                field("NCT Etax Download PDF File"; rec."NCT Etax Download PDF File")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Download PDF File field.';
                }
                field("NCT Etax Download Text File"; rec."NCT Etax Download Text File")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Download Text File field.';
                }
            }
        }
    }
}
