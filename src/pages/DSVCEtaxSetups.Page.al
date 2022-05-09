/// <summary>
/// Page DSVCEtaxSetups (ID 70200).
/// </summary>
page 70200 "DSVCEtaxSetups"
{
    SourceTable = "DSVCEtaxApi Setup";
    SourceTableView = sorting("DSVC Entry No.");
    ApplicationArea = all;
    PageType = List;
    UsageCategory = Lists;
    Caption = 'Etax Setup';
    layout
    {
        area(Content)
        {
            repeater("DSVCLines")
            {
                ShowCaption = false;
                field("DSVCAPI Name"; rec."DSVC API Name")
                {
                    ApplicationArea = all;
                    ToolTip = 'API Field Name';
                }
                field("DSVCAPI Value"; rec."DSVC API Value")
                {
                    ApplicationArea = all;
                    ToolTip = 'API Value';
                }
                field("DSVC Remark"; rec."DSVC Remark")
                {
                    ApplicationArea = all;
                    ToolTip = 'Remark';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group("DSVC InsertTemplateApi")
            {
                Caption = 'Insert Api Template';
                action("DSVC Template")
                {
                    Caption = 'API Template';
                    Image = Add;
                    ApplicationArea = all;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Add Template Api Setup';
                    trigger OnAction()
                    var
                        DSVCEtaxApiSetup: Record "DSVCEtaxApi Setup";
                        CompanyInformation: Record "Company Information";
                        BranchCode: Code[12];
                    begin
                        CompanyInformation.GET();
                        BranchCode := CompanyInformation."DSVC Etax Branch Code";
                        if CompanyInformation."DSVC Etax Branch Code" = '' then
                            BranchCode := '00000';

                        DSVCEtaxApiSetup.init();
                        DSVCEtaxApiSetup."DSVC Entry No." := 1;
                        DSVCEtaxApiSetup."DSVC API Name" := 'APIKey';
                        DSVCEtaxApiSetup."DSVC API Value" := '';
                        DSVCEtaxApiSetup."DSVC Remark" := 'API Keyfor Access';
                        DSVCEtaxApiSetup.Insert();

                        DSVCEtaxApiSetup.init();
                        DSVCEtaxApiSetup."DSVC Entry No." := 2;
                        DSVCEtaxApiSetup."DSVC API Name" := 'SellerBranchID';
                        DSVCEtaxApiSetup."DSVC API Value" := BranchCode;
                        DSVCEtaxApiSetup."DSVC Remark" := 'สาขาผู้เสียภาษี';
                        DSVCEtaxApiSetup.Insert();

                        DSVCEtaxApiSetup.init();
                        DSVCEtaxApiSetup."DSVC Entry No." := 3;
                        DSVCEtaxApiSetup."DSVC API Name" := 'SellerTaxID';
                        DSVCEtaxApiSetup."DSVC API Value" := CompanyInformation."VAT Registration No.";
                        DSVCEtaxApiSetup."DSVC Remark" := 'เลขประจำตัวผู้เสียภาษี';
                        DSVCEtaxApiSetup.Insert();

                        DSVCEtaxApiSetup.init();
                        DSVCEtaxApiSetup."DSVC Entry No." := 4;
                        DSVCEtaxApiSetup."DSVC API Name" := 'ServiceCode';
                        DSVCEtaxApiSetup."DSVC API Value" := 'S03';
                        DSVCEtaxApiSetup."DSVC Remark" := 'S03 (input : CSV, output : XML, PDF/A3) , S06 (input : CSV, PDF output : XML, PDF/A3)';
                        DSVCEtaxApiSetup.Insert();

                        DSVCEtaxApiSetup.init();
                        DSVCEtaxApiSetup."DSVC Entry No." := 5;
                        DSVCEtaxApiSetup."DSVC API Name" := 'UserCode';
                        DSVCEtaxApiSetup."DSVC API Value" := '';
                        DSVCEtaxApiSetup."DSVC Remark" := 'User Name for Access';
                        DSVCEtaxApiSetup.Insert();

                        DSVCEtaxApiSetup.init();
                        DSVCEtaxApiSetup."DSVC Entry No." := 6;
                        DSVCEtaxApiSetup."DSVC API Name" := 'AccessKey';
                        DSVCEtaxApiSetup."DSVC API Value" := '';
                        DSVCEtaxApiSetup."DSVC Remark" := 'Password for Access';
                        DSVCEtaxApiSetup.Insert();
                    end;
                }
            }
        }
    }
}