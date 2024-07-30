/// <summary>
/// PageExtension NCT Etax Pstd. Sales Cr. Memo (ID 80209) extends Record Pstd. Sales Cr. Memo - Update.
/// </summary>
pageextension 80209 "NCT Etax Pstd. Sales Cr. Memo" extends "Pstd. Sales Cr. Memo - Update"
{
    layout
    {
        addafter(General)
        {
            group(ETaxInformation)
            {
                Caption = 'E-Tax Information';
                field("NCT Etax Purpose"; rec."NCT Etax Purpose")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the E-Tax Purpose field.';
                    ShowMandatory = true;
                    trigger OnValidate()
                    begin
                        CheckPurpose();
                        CurrPage.Update();
                    end;
                }
                field("NCT Etax Purpose Remark"; rec."NCT Etax Purpose Remark")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the E-Tax Purpose Remark field.';
                    Editable = LockField;
                    ShowMandatory = true;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        CheckPurpose();
    end;

    local procedure CheckPurpose()
    begin
        LockField := rec."NCT Etax Purpose" in [rec."NCT Etax Purpose"::CDNG99, rec."NCT Etax Purpose"::CDNS99];
    end;

    var
        LockField: Boolean;

}
