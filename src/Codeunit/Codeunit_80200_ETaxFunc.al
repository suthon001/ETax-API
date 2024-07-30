/// <summary>
/// Codeunit NCT ETaxFunc (ID 80200).
/// </summary>
codeunit 80200 "NCT ETaxFunc"
{
    Permissions = tabledata "Sales Invoice Header" = rm, tabledata "Sales Cr.Memo Header" = rm, tabledata "NCT Billing Receipt Header" = rm;
    [EventSubscriber(ObjectType::page, page::"Pstd. Sales Cr. Memo - Update", 'OnAfterRecordChanged', '', false, false)]
    local procedure OnAfterRecordChanged(var IsChanged: Boolean; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; xSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        IsChanged :=
                 (SalesCrMemoHeader."Shipping Agent Code" <> xSalesCrMemoHeader."Shipping Agent Code") or
                 (SalesCrMemoHeader."Shipping Agent Service Code" <> xSalesCrMemoHeader."Shipping Agent Service Code") or
                 (SalesCrMemoHeader."Package Tracking No." <> xSalesCrMemoHeader."Package Tracking No.") or
                 (SalesCrMemoHeader."Company Bank Account Code" <> xSalesCrMemoHeader."Company Bank Account Code") or
                 (SalesCrMemoHeader."Posting Description" <> xSalesCrMemoHeader."Posting Description") or
                  (SalesCrMemoHeader."NCT Etax Purpose" <> xSalesCrMemoHeader."NCT Etax Purpose") or
                   (SalesCrMemoHeader."NCT Etax Purpose Remark" <> xSalesCrMemoHeader."NCT Etax Purpose Remark");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Credit Memo Hdr. - Edit", 'OnBeforeSalesCrMemoHeaderModify', '', false, false)]
    local procedure OnBeforeSalesCrMemoHeaderModify(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader."NCT Etax Purpose" := FromSalesCrMemoHeader."NCT Etax Purpose";
        SalesCrMemoHeader."NCT Etax Purpose Remark" := FromSalesCrMemoHeader."NCT Etax Purpose Remark";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReleaseSalesDoc', '', false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then begin
            SalesHeader.TestField("NCT Etax Purpose");
            SalesHeader.TestField("NCT Etax Purpose Remark");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then begin
            SalesHeader.TestField("NCT Etax Purpose");
            SalesHeader.TestField("NCT Etax Purpose Remark");
        end;
    end;

    /// <summary>
    /// ETaxSalesReceip.
    /// </summary>
    /// <param name="pSalesReceipt">VAR Record "NCT Billing Receipt Header".</param>
    /// <param name="pEtaxType">Enum "NCT Etax Type".</param>
    procedure ETaxSalesReceip(var pSalesReceipt: Record "NCT Billing Receipt Header"; pEtaxType: Enum "NCT Etax Type")
    var
        Cust: Record Customer;
        SalesBillingLine: Record "NCT Billing Receipt Line";
        PaymentTerms: Record "Payment Terms";
        WHTBus: Record "NCT WHT Business Posting Group";
        ltTempblob: Codeunit "Temp Blob";
        ltOutStream: OutStream;
        ltInStream: InStream;
        ltFilenameLbl: Label 'SalesReceipt_%1_%2_%3';
        ltFileName, ToFileName : Text;
        DataText, ltVatBranch, ltCustVatBranch, EtaxData, NewLine : Text;
        CurrencyCode: Code[10];
        TotalSalesReceiptLine, LineNo : Integer;
        VatPer: Decimal;
        ltDocumentType: Enum "Etax Document Type";
        TotalAmt: array[100] of Decimal;
        ltHaveEmail: Boolean;
        CR: Char;
        LF: Char;
    begin
        CheckService();
        EntryNo := 0;
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CompanyInfo.GET();
        CompanyInfo.TestField("VAT Registration No.");
        if pSalesReceipt.FindSet() then
            repeat
                Clear(DataText);
                CLEAR(TotalAmt);
                CLEAR(EtaxData);
                LineNo := 0;
                Clear(ltTempblob);
                pSalesReceipt.CalcFields(Amount, "Amount (LCY)");
                if pSalesReceipt.Amount <> 0 then begin
                    Cust.GET(pSalesReceipt."Bill/Pay-to Cust/Vend No.");
                    if not PaymentTerms.GET(pSalesReceipt."Payment Terms Code") then
                        PaymentTerms.Init();
                    ltFileName := StrSubstNo(ltFilenameLbl, SalesReceivablesSetup."NCT Etax Seller Tax ID", pSalesReceipt."No.", pSalesReceipt."NCT Etax No. of Send" + 1) + '.txt';
                    ToFileName := StrSubstNo(ltFilenameLbl, SalesReceivablesSetup."NCT Etax Seller Tax ID", pSalesReceipt."No.", pSalesReceipt."NCT Etax No. of Send" + 1);
                    DataText := SetDataEtax('C', true);
                    DataText += SetDataEtax(DelChr(SalesReceivablesSetup."NCT Etax Seller Tax ID", '=', '-'), true);
                    if not WHTBus.GET(pSalesReceipt."WHT Business Posting Group") then
                        WHTBus.Init();
                    ltVatBranch := SalesReceivablesSetup."NCT Etax Seller Branch ID";

                    DataText += SetDataEtax(ltVatBranch, true);
                    DataText += SetDataEtax(ltFileName, false);
                    EtaxData := DataText + NewLine;

                    DataText := SetDataEtax('H', true); //1
                    DataText += SetDataEtax(GetEnumValueName(pEtaxType), true); //2
                    DataText += SetDataEtax(format(pEtaxType), true); // 3
                    DataText += SetDataEtax(pSalesReceipt."No.", true); //4
                    DataText += SetDataEtax(format(pSalesReceipt."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true); //5
                    DataText += SetDataEtax('', true);//6
                    DataText += SetDataEtax('', true);//7
                    DataText += SetDataEtax('', true);//8
                    DataText += SetDataEtax('', true);//9
                    DataText += SetDataEtax('', true);//10
                    DataText += SetDataEtax(pSalesReceipt."External Document No.", true);//11
                    DataText += SetDataEtax('', true);//12
                    DataText += SetDataEtax('', true);//13
                    DataText += SetDataEtax('', true);//14
                    DataText += SetDataEtax('', true);//15
                    DataText += SetDataEtax(pSalesReceipt.Remark, true);//16
                    DataText += SetDataEtax('', true);//17
                    DataText += SetDataEtax('', true);//18
                    DataText += SetDataEtax('', true);//19
                    DataText += SetDataEtax('', true);//20
                    DataText += SetDataEtax('', true);//21
                    DataText += SetDataEtax('', true);//22
                    DataText += SetDataEtax(ltVatBranch, true);//23
                    DataText += SetDataEtax('', true);//24
                    DataText += SetDataEtax('', true);//25
                    DataText += SetDataEtax('', true);//26
                    if Cust."E-Mail" <> '' then
                        DataText += SetDataEtax('Y', false) //27
                    else
                        DataText += SetDataEtax('N', false);
                    EtaxData := EtaxData + DataText + NewLine;


                    ltHaveEmail := Cust."E-Mail" <> '';
                    if Cust."NCT Head Office" then
                        ltCustVatBranch := '00000'
                    else
                        ltCustVatBranch := Cust."NCT VAT Branch Code";
                    if ltCustVatBranch = '' then
                        ltCustVatBranch := '00000';

                    DataText := SetDataEtax('B', true); //1
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Cust/Vend No.", true); //2
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Cust/Vend Name" + ' ' + pSalesReceipt."Bill/Pay-to Cust/Vend Name 2", true); //3
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::" " then
                        DataText += SetDataEtax('', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.3" then
                        DataText += SetDataEtax('NIDN', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                        DataText += SetDataEtax('TXID', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.54" then
                        DataText += SetDataEtax('CCPT', true);

                    DataText += SetDataEtax(DelChr(pSalesReceipt."VAT Registration No.", '=', '-'), true); //5
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                        DataText += SetDataEtax(ltCustVatBranch, true)
                    else
                        DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Contact", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(Cust."E-Mail", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Post Code", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Address" + ' ' + pSalesReceipt."Bill/Pay-to Address 2", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Post Code", true);
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to City", true);
                    DataText += SetDataEtax(pSalesReceipt."Bill/Pay-to Country/Region", false);
                    EtaxData := EtaxData + DataText + NewLine;

                    if pSalesReceipt."Currency Code" <> '' then
                        CurrencyCode := CopyStr(CurrencyCode, 1, 3)
                    else
                        CurrencyCode := 'THB';
                    SalesBillingLine.reset();
                    SalesBillingLine.SetRange("Document Type", pSalesReceipt."Document Type");
                    SalesBillingLine.SetRange("Document No.", pSalesReceipt."No.");
                    SalesBillingLine.SetFilter("Source Document No.", '<>%1', '');
                    TotalSalesReceiptLine := SalesBillingLine.count();
                    if SalesBillingLine.FindSet() then
                        repeat
                            LineNo += 1;
                            DataText := SetDataEtax('L', true); //1
                            DataText += SetDataEtax(format(LineNo), true); //2
                            DataText += SetDataEtax(format(SalesBillingLine."Source Ledger Entry No."), true); //3
                            DataText += SetDataEtax(SalesBillingLine."Source Document No." + ' ' + SalesBillingLine."Source Description", true); //4
                            DataText += SetDataEtax('', true); //5
                            DataText += SetDataEtax('', true); //6
                            DataText += SetDataEtax('', true); //7
                            DataText += SetDataEtax('', true); //8
                            DataText += SetDataEtax('', true); //9
                            DataText += SetDataEtax('', true); //10
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true); //11
                            DataText += SetDataEtax(CurrencyCode, true); //12
                            DataText += SetDataEtax('', true); //13
                            DataText += SetDataEtax('', true); //14
                            DataText += SetDataEtax('', true); //15
                            DataText += SetDataEtax('', true); //16
                            DataText += SetDataEtax('', true); //17
                            DataText += SetDataEtax('', true); //18
                            DataText += SetDataEtax('', true); //19
                            DataText += SetDataEtax('', true); //20
                            DataText += SetDataEtax('VAT', true); //21
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine."Vat %", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true); //22
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine.Amount - SalesBillingLine."Amount Exclude Vat", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine.Amount - SalesBillingLine."Amount Exclude Vat", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine."Amount Exclude Vat", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesBillingLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            if TotalSalesReceiptLine <> LineNo then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax(CurrencyCode, false);
                            EtaxData := EtaxData + DataText + NewLine;
                        until SalesBillingLine.next() = 0;

                    SalesBillingLine.reset();
                    SalesBillingLine.SetRange("Document No.", pSalesReceipt."No.");
                    SalesBillingLine.CalcSums("Amount Exclude Vat");
                    TotalAmt[3] := SalesBillingLine."Amount Exclude Vat";

                    TotalAmt[1] := pSalesReceipt.Amount;
                    TotalAmt[4] := pSalesReceipt.Amount - SalesBillingLine."Amount Exclude Vat";
                    if TotalAmt[4] <> 0 then
                        VatPer := 7.00;
                    TotalAmt[5] := pSalesReceipt.Amount;

                    DataText := SetDataEtax('F', true);
                    DataText += SetDataEtax(format(TotalSalesReceiptLine), true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('VAT', true);
                    DataText += SetDataEtax(DelChr(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(PaymentTerms.Description, true);
                    DataText += SetDataEtax(format(pSalesReceipt."Due Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                    DataText := SetDataEtax('T', True);
                    DataText += SetDataEtax('1', false);
                    EtaxData := EtaxData + DataText;
                    ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
                    ltOutStream.WriteText(EtaxData);
                    ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
                    if CallEtaxWebservice(ltDocumentType::"Sales Receipt", pSalesReceipt."No.", ToFileName, ltInStream, pEtaxType) then begin
                        pSalesReceipt."NCT Etax Send to E-Tax" := true;
                        pSalesReceipt."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, MaxStrLen(pSalesReceipt."NCT Etax Last File Name"));
                        pSalesReceipt."NCT Etax Send By" := COPYSTR(USERID, 1, MaxStrLen(pSalesReceipt."NCT Etax Send By"));
                        pSalesReceipt."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesReceipt."NCT Etax No. of Send" := pSalesReceipt."NCT Etax No. of Send" + 1;
                        pSalesReceipt."NCT Etax Status" := pSalesReceipt."NCT Etax Status"::Completely;
                        pSalesReceipt."Have Email" := ltHaveEmail;
                        pSalesReceipt.Modify();
                        CreateToZipFile(StrSubstNo('SalesReceipt_%1', pSalesReceipt."No."), pSalesReceipt."No.");
                    end else begin
                        pSalesReceipt."NCT Etax Send to E-Tax" := false;
                        pSalesReceipt."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, MaxStrLen(pSalesReceipt."NCT Etax Last File Name"));
                        pSalesReceipt."NCT Etax Send By" := COPYSTR(USERID, 1, MaxStrLen(pSalesReceipt."NCT Etax Send By"));
                        pSalesReceipt."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesReceipt."NCT Etax No. of Send" := pSalesReceipt."NCT Etax No. of Send" + 1;
                        pSalesReceipt."NCT Etax Status" := pSalesReceipt."NCT Etax Status"::Fail;
                        pSalesReceipt."Have Email" := ltHaveEmail;
                        pSalesReceipt.Modify();
                    end;
                    CreateLogEtax(pSalesReceipt."NCT Etax Status");
                end;
            until pSalesReceipt.Next() = 0;
    end;

    /// <summary>
    /// ETaxSalesInvoice.
    /// </summary>
    /// <param name="pSalesInvHeader">VAR Record "Sales Invoice Header".</param>
    /// <param name="pEtaxType">Enum "NCT Etax Type".</param>
    procedure ETaxSalesInvoice(var pSalesInvHeader: Record "Sales Invoice Header"; pEtaxType: Enum "NCT Etax Type")
    var
        Cust: Record Customer;
        SalesInvoiceLine: Record "Sales Invoice Line";
        Itemcategory: Record "Item Category";
        PaymentTerms: Record "Payment Terms";
        ltItem: Record Item;
        WHTBus: Record "NCT WHT Business Posting Group";
        ltTempblob: Codeunit "Temp Blob";
        ltOutStream: OutStream;
        ltInStream: InStream;
        ltFilenameLbl: Label 'SalesInvoice_%1_%2_%3';
        ltFileName, ToFileName : Text;
        DataText, ltVatBranch, ltCustVatBranch, EtaxData, NewLine : Text;
        CurrencyCode: Code[10];
        TotalSalesInvoiceLine, LineNo : Integer;
        VatPer, TotalLineDisAmt : Decimal;
        TotalAmt: array[100] of Decimal;
        ltDocumentType: Enum "Etax Document Type";
        ltHaveEmail: Boolean;
        CR: Char;
        LF: Char;
    begin
        CheckService();
        EntryNo := 0;
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CompanyInfo.GET();
        CompanyInfo.TestField("VAT Registration No.");
        if pSalesInvHeader.FindSet() then
            repeat
                Clear(DataText);
                CLEAR(TotalAmt);
                CLEAR(EtaxData);
                LineNo := 0;
                Clear(ltTempblob);
                pSalesInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
                if pSalesInvHeader."Amount Including VAT" <> 0 then begin
                    Cust.GET(pSalesInvHeader."Sell-to Customer No.");
                    if not PaymentTerms.GET(pSalesInvHeader."Payment Terms Code") then
                        PaymentTerms.Init();
                    ltFileName := StrSubstNo(ltFilenameLbl, SalesReceivablesSetup."NCT Etax Seller Tax ID", pSalesInvHeader."No.", pSalesInvHeader."NCT Etax No. of Send" + 1) + '.txt';
                    ToFileName := StrSubstNo(ltFilenameLbl, SalesReceivablesSetup."NCT Etax Seller Tax ID", pSalesInvHeader."No.", pSalesInvHeader."NCT Etax No. of Send" + 1);
                    DataText := SetDataEtax('C', true);
                    DataText += SetDataEtax(DelChr(SalesReceivablesSetup."NCT Etax Seller Tax ID", '=', '-'), true);
                    if not WHTBus.GET(pSalesInvHeader."NCT WHT Business Posting Group") then
                        WHTBus.Init();

                    ltVatBranch := SalesReceivablesSetup."NCT Etax Seller Branch ID";

                    DataText += SetDataEtax(ltVatBranch, true);
                    DataText += SetDataEtax(ltFileName, false);
                    EtaxData := DataText + NewLine;

                    DataText := SetDataEtax('H', true); //1
                    DataText += SetDataEtax(GetEnumValueName(pEtaxType), true); //2
                    DataText += SetDataEtax(format(pEtaxType), true); // 3
                    DataText += SetDataEtax(pSalesInvHeader."No.", true); //4
                    DataText += SetDataEtax(format(pSalesInvHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true); //5
                    DataText += SetDataEtax('', true);//6
                    DataText += SetDataEtax('', true);//7
                    DataText += SetDataEtax('', true);//8
                    DataText += SetDataEtax('', true);//9
                    DataText += SetDataEtax('', true);//10
                    DataText += SetDataEtax(pSalesInvHeader."External Document No.", true);//11
                    DataText += SetDataEtax('', true);//12
                    DataText += SetDataEtax('', true);//13
                    DataText += SetDataEtax('', true);//14
                    DataText += SetDataEtax('', true);//15
                    DataText += SetDataEtax('', true);//16
                    DataText += SetDataEtax('', true);//17
                    DataText += SetDataEtax('', true);//18
                    DataText += SetDataEtax('', true);//19
                    DataText += SetDataEtax('', true);//20
                    DataText += SetDataEtax('', true);//21
                    DataText += SetDataEtax('', true);//22
                    DataText += SetDataEtax(ltVatBranch, true);//23
                    DataText += SetDataEtax('', true);//24
                    DataText += SetDataEtax('', true);//25
                    DataText += SetDataEtax('', true);//26
                    if Cust."E-Mail" <> '' then
                        DataText += SetDataEtax('Y', false) //27
                    else
                        DataText += SetDataEtax('N', false);
                    EtaxData := EtaxData + DataText + NewLine;
                    ltHaveEmail := Cust."E-Mail" <> '';

                    if not Cust.GET(pSalesInvHeader."Bill-to Customer No.") then
                        Cust.Init();

                    if Cust."NCT Head Office" then
                        ltCustVatBranch := '00000'
                    else
                        ltCustVatBranch := Cust."NCT VAT Branch Code";
                    if ltCustVatBranch = '' then
                        ltCustVatBranch := '00000';

                    DataText := SetDataEtax('B', true); //1
                    DataText += SetDataEtax(pSalesInvHeader."Bill-to Customer No.", true); //2
                    DataText += SetDataEtax(pSalesInvHeader."Bill-to Name" + ' ' + pSalesInvHeader."Bill-to Name 2", true); //3
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::" " then
                        DataText += SetDataEtax('', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.3" then
                        DataText += SetDataEtax('NIDN', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                        DataText += SetDataEtax('TXID', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.54" then
                        DataText += SetDataEtax('CCPT', true);

                    DataText += SetDataEtax(DelChr(pSalesInvHeader."VAT Registration No.", '=', '-'), true); //5
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                        DataText += SetDataEtax(ltCustVatBranch, true)
                    else
                        DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesInvHeader."Bill-to Contact", true);
                    DataText += SetDataEtax('', true);
                    Cust.get(pSalesInvHeader."Sell-to Customer No.");
                    DataText += SetDataEtax(Cust."E-Mail", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesInvHeader."bill-to Post Code", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesInvHeader."bill-to Address" + ' ' + pSalesInvHeader."bill-to Address 2", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesInvHeader."bill-to Post Code", true);
                    DataText += SetDataEtax(pSalesInvHeader."bill-to City", true);
                    DataText += SetDataEtax(pSalesInvHeader."bill-to Country/Region Code", false);
                    EtaxData := EtaxData + DataText + NewLine;

                    if pSalesInvHeader."Currency Code" <> '' then
                        CurrencyCode := CopyStr(CurrencyCode, 1, 3)
                    else
                        CurrencyCode := 'THB';
                    SalesInvoiceLine.reset();
                    SalesInvoiceLine.SetRange("Document No.", pSalesInvHeader."No.");
                    SalesInvoiceLine.SetFilter("No.", '<>%1', '');
                    TotalSalesInvoiceLine := SalesInvoiceLine.count();
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            LineNo += 1;
                            if not ltItem.GET(SalesInvoiceLine."No.") then
                                ltItem.init();
                            if not Itemcategory.GET(ltItem."Item Category Code") then
                                Itemcategory.Init();



                            DataText := SetDataEtax('L', true); //1
                            DataText += SetDataEtax(format(LineNo), true); //2
                            DataText += SetDataEtax(SalesInvoiceLine."No.", true); //3
                            DataText += SetDataEtax(SalesInvoiceLine.Description + ' ' + SalesInvoiceLine."Description 2", true); //4
                            DataText += SetDataEtax('', true); //5
                            DataText += SetDataEtax('', true); //6
                            DataText += SetDataEtax('', true); //7
                            DataText += SetDataEtax(ltItem."Item Category Code", true); //8
                            DataText += SetDataEtax(Itemcategory.Description, true); //9
                            DataText += SetDataEtax('', true); //10
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."Unit Price", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true); //11
                            DataText += SetDataEtax(CurrencyCode, true); //12
                            DataText += SetDataEtax('', true); //13
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."Line Discount Amount", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true); //14
                            if SalesInvoiceLine."Line Discount Amount" <> 0 then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true); //16
                            DataText += SetDataEtax('', true); //17
                            DataText += SetDataEtax(format(SalesInvoiceLine.Quantity), true); //18
                            DataText += SetDataEtax(SalesInvoiceLine."Unit of Measure Code", true); //19
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."Qty. per Unit of Measure", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true); //20
                            DataText += SetDataEtax('VAT', true); //21
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."VAT %", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true); //22
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesInvoiceLine."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            if TotalSalesInvoiceLine <> LineNo then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax(CurrencyCode, false);
                            EtaxData := EtaxData + DataText + NewLine;
                        until SalesInvoiceLine.next() = 0;
                    SalesInvoiceLine.reset();
                    SalesInvoiceLine.SetRange("Document No.", pSalesInvHeader."No.");
                    SalesInvoiceLine.SetFilter("VAT %", '<>%1', 0);
                    if SalesInvoiceLine.FindFirst() then
                        VatPer := SalesInvoiceLine."VAT %";

                    TotalLineDisAmt := pSalesInvHeader."Invoice Discount Amount";

                    SalesInvoiceLine.Reset();
                    SalesInvoiceLine.SetRange("Document No.", pSalesInvHeader."No.");
                    SalesInvoiceLine.Setfilter("Line Amount", '<%1', 0);
                    if SalesInvoiceLine.FindSet() then begin
                        SalesInvoiceLine.CalcSums("Line Amount");
                        TotalLineDisAmt := TotalLineDisAmt + ABS(SalesInvoiceLine."Line Amount");

                    end;
                    NCTLCLFunction.PostedSalesInvoiceStatistics(pSalesInvHeader."No.", TotalAmt, VATText);

                    DataText := SetDataEtax('F', true);
                    DataText += SetDataEtax(format(TotalSalesInvoiceLine), true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('VAT', true);
                    DataText += SetDataEtax(DelChr(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(PaymentTerms.Description, true);
                    DataText += SetDataEtax(format(pSalesInvHeader."Due Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                    DataText := SetDataEtax('T', True);
                    DataText += SetDataEtax('1', false);
                    EtaxData := EtaxData + DataText;
                    ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
                    ltOutStream.WriteText(EtaxData);
                    ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
                    if CallEtaxWebservice(ltDocumentType::"Sales Invoice", pSalesInvHeader."No.", ToFileName, ltInStream, pEtaxType) then begin
                        pSalesInvHeader."NCT Etax Send to E-Tax" := true;
                        pSalesInvHeader."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, MaxStrLen(pSalesInvHeader."NCT Etax Last File Name"));
                        pSalesInvHeader."NCT Etax Send By" := COPYSTR(USERID, 1, MaxStrLen(pSalesInvHeader."NCT Etax Send By"));
                        pSalesInvHeader."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesInvHeader."NCT Etax No. of Send" := pSalesInvHeader."NCT Etax No. of Send" + 1;
                        pSalesInvHeader."NCT Etax Status" := pSalesInvHeader."NCT Etax Status"::Completely;
                        pSalesInvHeader."Have Email" := ltHaveEmail;
                        pSalesInvHeader.Modify();
                        CreateToZipFile(StrSubstNo('SalesInvoice_%1', pSalesInvHeader."No."), pSalesInvHeader."No.");
                    end else begin
                        pSalesInvHeader."NCT Etax Send to E-Tax" := false;
                        pSalesInvHeader."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, MaxStrLen(pSalesInvHeader."NCT Etax Last File Name"));
                        pSalesInvHeader."NCT Etax Send By" := COPYSTR(USERID, 1, MaxStrLen(pSalesInvHeader."NCT Etax Send By"));
                        pSalesInvHeader."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesInvHeader."NCT Etax No. of Send" := pSalesInvHeader."NCT Etax No. of Send" + 1;
                        pSalesInvHeader."NCT Etax Status" := pSalesInvHeader."NCT Etax Status"::Fail;
                        pSalesInvHeader."Have Email" := ltHaveEmail;
                        pSalesInvHeader.Modify();
                    end;
                    CreateLogEtax(pSalesInvHeader."NCT Etax Status");
                end;
            until pSalesInvHeader.Next() = 0;
    end;

    /// <summary>
    /// ETaxSalesCreditMemo.
    /// </summary>
    /// <param name="pSalesCreditMemo">VAR Record "Sales Cr.Memo Header".</param>
    /// <param name="pEtaxType">Enum "NCT Etax Type".</param>
    procedure ETaxSalesCreditMemo(var pSalesCreditMemo: Record "Sales Cr.Memo Header"; pEtaxType: Enum "NCT Etax Type")
    var
        Cust: Record Customer;
        SalesCreditMemoLine: Record "Sales Cr.Memo Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Itemcategory: Record "Item Category";
        PaymentTerms: Record "Payment Terms";
        ltItem: Record Item;
        WHTBus: Record "NCT WHT Business Posting Group";
        ltTempblob: Codeunit "Temp Blob";
        ltEtaxLog: Record "NCT Etax Log";
        ltOutStream: OutStream;
        ltInStream: InStream;
        ltFilenameLbl: Label 'SalesCreditMemo_%1_%2_%3';
        ltFileName, ToFileName : Text;
        DataText, ltVatBranch, ltCustVatBranch, EtaxData, NewLine : Text;
        CurrencyCode: Code[10];
        TotalSalesCreditLine, LineNo : Integer;
        ltApplyDocID: Code[50];
        ltInvoiceEtaxCode: code[20];
        VatPer, TotalLineDisAmt : Decimal;
        TotalAmt: array[100] of Decimal;
        ltDocumentType: Enum "Etax Document Type";
        ltHaveEmail: Boolean;
        CR: Char;
        LF: Char;
    begin
        CheckService();
        EntryNo := 0;
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CompanyInfo.GET();
        CompanyInfo.TestField("VAT Registration No.");
        if pSalesCreditMemo.FindSet() then
            repeat
                Clear(DataText);
                CLEAR(TotalAmt);
                CLEAR(EtaxData);
                LineNo := 0;
                Clear(ltTempblob);
                pSalesCreditMemo.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
                if pSalesCreditMemo."Amount Including VAT" <> 0 then begin
                    if pSalesCreditMemo."Applies-to Doc. No." <> '' then
                        ltApplyDocID := pSalesCreditMemo."Applies-to Doc. No."
                    else
                        ltApplyDocID := pSalesCreditMemo."NCT Applies-to ID";

                    if ltApplyDocID = '' then
                        ERROR('Applies ID must spacifies');

                    Cust.GET(pSalesCreditMemo."Sell-to Customer No.");
                    if not PaymentTerms.GET(pSalesCreditMemo."Payment Terms Code") then
                        PaymentTerms.Init();

                    ltInvoiceEtaxCode := '';
                    ltEtaxLog.reset();
                    ltEtaxLog.SetRange("Document Type", ltEtaxLog."Document Type"::"Sales Invoice");
                    ltEtaxLog.SetRange(Status, ltEtaxLog.Status::Completely);
                    ltEtaxLog.SetRange("Document No.", ltApplyDocID);
                    if ltEtaxLog.FindFirst() then
                        ltInvoiceEtaxCode := ltEtaxLog."Etax Type Code";
                    ltFileName := StrSubstNo(ltFilenameLbl, SalesReceivablesSetup."NCT Etax Seller Tax ID", pSalesCreditMemo."No.", pSalesCreditMemo."NCT Etax No. of Send" + 1) + '.txt';
                    ToFileName := StrSubstNo(ltFilenameLbl, SalesReceivablesSetup."NCT Etax Seller Tax ID", pSalesCreditMemo."No.", pSalesCreditMemo."NCT Etax No. of Send" + 1);
                    DataText := SetDataEtax('C', true);
                    DataText += SetDataEtax(DelChr(SalesReceivablesSetup."NCT Etax Seller Tax ID", '=', '-'), true);
                    if not WHTBus.GET(pSalesCreditMemo."NCT WHT Business Posting Group") then
                        WHTBus.Init();

                    ltVatBranch := SalesReceivablesSetup."NCT Etax Seller Branch ID";

                    DataText += SetDataEtax(ltVatBranch, true);
                    DataText += SetDataEtax(ltFileName, false);
                    EtaxData := DataText + NewLine;

                    DataText := SetDataEtax('H', true); //1
                    DataText += SetDataEtax(GetEnumValueName(pEtaxType), true); //2
                    DataText += SetDataEtax(format(pEtaxType), true); // 3
                    DataText += SetDataEtax(pSalesCreditMemo."No.", true); //4
                    DataText += SetDataEtax(format(pSalesCreditMemo."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true); //5
                    DataText += SetDataEtax(GetEnumEtaxPurposeValueName(pSalesCreditMemo."NCT Etax Purpose"), true);//6
                    DataText += SetDataEtax(pSalesCreditMemo."NCT Etax Purpose Remark", true);//7
                    DataText += SetDataEtax(ltApplyDocID, true);//8
                    DataText += SetDataEtax(format(pSalesCreditMemo."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);//9
                    DataText += SetDataEtax(ltInvoiceEtaxCode, true);//10
                    DataText += SetDataEtax(pSalesCreditMemo."External Document No.", true);//11
                    DataText += SetDataEtax('', true);//12
                    DataText += SetDataEtax('', true);//13
                    DataText += SetDataEtax('', true);//14
                    DataText += SetDataEtax('', true);//15
                    DataText += SetDataEtax('', true);//16
                    DataText += SetDataEtax('', true);//17
                    DataText += SetDataEtax('', true);//18
                    DataText += SetDataEtax('', true);//19
                    DataText += SetDataEtax('', true);//20
                    DataText += SetDataEtax('', true);//21
                    DataText += SetDataEtax('', true);//22
                    DataText += SetDataEtax(ltVatBranch, true);//23
                    DataText += SetDataEtax('', true);//24
                    DataText += SetDataEtax('', true);//25
                    DataText += SetDataEtax('', true);//26
                    if Cust."E-Mail" <> '' then
                        DataText += SetDataEtax('Y', false) //27
                    else
                        DataText += SetDataEtax('N', false);
                    EtaxData := EtaxData + DataText + NewLine;
                    ltHaveEmail := Cust."E-Mail" <> '';
                    if not Cust.GET(pSalesCreditMemo."Bill-to Customer No.") then
                        Cust.Init();

                    if Cust."NCT Head Office" then
                        ltCustVatBranch := '00000'
                    else
                        ltCustVatBranch := Cust."NCT VAT Branch Code";
                    if ltCustVatBranch = '' then
                        ltCustVatBranch := '00000';

                    DataText := SetDataEtax('B', true); //1
                    DataText += SetDataEtax(pSalesCreditMemo."Bill-to Customer No.", true); //2
                    DataText += SetDataEtax(pSalesCreditMemo."Bill-to Name" + ' ' + pSalesCreditMemo."Bill-to Name 2", true); //3
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::" " then
                        DataText += SetDataEtax('', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.3" then
                        DataText += SetDataEtax('NIDN', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                        DataText += SetDataEtax('TXID', true);
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.54" then
                        DataText += SetDataEtax('CCPT', true);

                    DataText += SetDataEtax(DelChr(pSalesCreditMemo."VAT Registration No.", '=', '-'), true); //5
                    if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                        DataText += SetDataEtax(ltCustVatBranch, true)
                    else
                        DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesCreditMemo."Bill-to Contact", true);
                    DataText += SetDataEtax('', true);
                    Cust.get(pSalesCreditMemo."Sell-to Customer No.");
                    DataText += SetDataEtax(Cust."E-Mail", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesCreditMemo."bill-to Post Code", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesCreditMemo."bill-to Address" + ' ' + pSalesCreditMemo."bill-to Address 2", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(pSalesCreditMemo."bill-to Post Code", true);
                    DataText += SetDataEtax(pSalesCreditMemo."bill-to City", true);
                    DataText += SetDataEtax(pSalesCreditMemo."bill-to Country/Region Code", false);
                    EtaxData := EtaxData + DataText + NewLine;

                    if pSalesCreditMemo."Currency Code" <> '' then
                        CurrencyCode := CopyStr(CurrencyCode, 1, 3)
                    else
                        CurrencyCode := 'THB';
                    SalesCreditMemoLine.reset();
                    SalesCreditMemoLine.SetRange("Document No.", pSalesCreditMemo."No.");
                    SalesCreditMemoLine.SetFilter("No.", '<>%1', '');
                    TotalSalesCreditLine := SalesCreditMemoLine.count();
                    if SalesCreditMemoLine.FindSet() then
                        repeat
                            LineNo += 1;
                            if not ltItem.GET(SalesCreditMemoLine."No.") then
                                ltItem.init();
                            if not Itemcategory.GET(ltItem."Item Category Code") then
                                Itemcategory.Init();



                            DataText := SetDataEtax('L', true);
                            DataText += SetDataEtax(format(LineNo), true);
                            DataText += SetDataEtax(SalesCreditMemoLine."No.", true);
                            DataText += SetDataEtax(SalesCreditMemoLine.Description + ' ' + SalesCreditMemoLine."Description 2", true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(ltItem."Item Category Code", true);
                            DataText += SetDataEtax(Itemcategory.Description, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."Unit Price", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."Line Discount Amount", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            if SalesCreditMemoLine."Line Discount Amount" <> 0 then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine.Quantity), true);
                            DataText += SetDataEtax(SalesCreditMemoLine."Unit of Measure Code", true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."Qty. per Unit of Measure", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax('VAT', true); //21
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."VAT %", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."Amount Including VAT" - SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."Amount Including VAT" - SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(DelChr(format(SalesCreditMemoLine."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                            if TotalSalesCreditLine <> LineNo then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax(CurrencyCode, false);
                            EtaxData := EtaxData + DataText + NewLine;
                        until SalesCreditMemoLine.next() = 0;

                    SalesCreditMemoLine.reset();
                    SalesCreditMemoLine.SetRange("Document No.", pSalesCreditMemo."No.");
                    SalesCreditMemoLine.SetFilter("VAT %", '<>%1', 0);
                    if SalesCreditMemoLine.FindFirst() then
                        VatPer := SalesCreditMemoLine."VAT %";

                    TotalLineDisAmt := pSalesCreditMemo."Invoice Discount Amount";

                    SalesCreditMemoLine.Reset();
                    SalesCreditMemoLine.SetRange("Document No.", pSalesCreditMemo."No.");
                    SalesCreditMemoLine.Setfilter("Line Amount", '<%1', 0);
                    if SalesCreditMemoLine.FindSet() then begin
                        SalesCreditMemoLine.CalcSums("Line Amount");
                        TotalLineDisAmt := TotalLineDisAmt + ABS(SalesCreditMemoLine."Line Amount");

                    end;
                    NCTLCLFunction.PostedSalesCrMemoStatistics(pSalesCreditMemo."No.", TotalAmt, VATText);

                    CustLedgEntry.Reset();
                    IF pSalesCreditMemo."Applies-to Doc. No." <> '' THEN
                        CustLedgEntry.SETFILTER("Document No.", '%1', pSalesCreditMemo."Applies-to Doc. No.")
                    ELSE
                        CustLedgEntry.SETFILTER("Document No.", '%1', pSalesCreditMemo."NCT Applies-to ID");
                    IF CustLedgEntry.FindFirst() THEN BEGIN
                        TotalAmt[98] := CustLedgEntry."Original Amt. (LCY)";
                        if pSalesCreditMemo."NCT Ref. Tax Invoice Amount" <> 0 then
                            TotalAmt[100] := pSalesCreditMemo."NCT Ref. Tax Invoice Amount"
                        else
                            TotalAmt[100] := CustLedgEntry."Sales (LCY)";

                    END ELSE
                        TotalAmt[100] := pSalesCreditMemo."NCT Ref. Tax Invoice Amount";
                    TotalAmt[99] := TotalAmt[100] - TotalAmt[1];


                    DataText := SetDataEtax('F', true);
                    DataText += SetDataEtax(format(TotalSalesCreditLine), true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('VAT', true);
                    DataText += SetDataEtax(DelChr(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(PaymentTerms.Description, true);
                    DataText += SetDataEtax(format(pSalesCreditMemo."Due Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[99], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[100], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(DelChr(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), '=', ','), true);
                    DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                    DataText := SetDataEtax('T', True);
                    DataText += SetDataEtax('1', false);
                    EtaxData := EtaxData + DataText;
                    ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
                    ltOutStream.WriteText(EtaxData);
                    ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
                    if CallEtaxWebservice(ltDocumentType::"Sales Credit Memo", pSalesCreditMemo."No.", ToFileName, ltInStream, pEtaxType) then begin
                        pSalesCreditMemo."NCT Etax Send to E-Tax" := true;
                        pSalesCreditMemo."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, MaxStrLen(pSalesCreditMemo."NCT Etax Last File Name"));
                        pSalesCreditMemo."NCT Etax Send By" := COPYSTR(USERID, 1, MaxStrLen(pSalesCreditMemo."NCT Etax Send By"));
                        pSalesCreditMemo."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesCreditMemo."NCT Etax No. of Send" := pSalesCreditMemo."NCT Etax No. of Send" + 1;
                        pSalesCreditMemo."NCT Etax Status" := pSalesCreditMemo."NCT Etax Status"::Completely;
                        pSalesCreditMemo."Have Email" := ltHaveEmail;
                        pSalesCreditMemo.Modify();
                        CreateToZipFile(StrSubstNo('SalesCreditMemo_%1', pSalesCreditMemo."No."), pSalesCreditMemo."No.");
                    end else begin
                        pSalesCreditMemo."NCT Etax Send to E-Tax" := false;
                        pSalesCreditMemo."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, MaxStrLen(pSalesCreditMemo."NCT Etax Last File Name"));
                        pSalesCreditMemo."NCT Etax Send By" := COPYSTR(USERID, 1, MaxStrLen(pSalesCreditMemo."NCT Etax Send By"));
                        pSalesCreditMemo."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesCreditMemo."NCT Etax No. of Send" := pSalesCreditMemo."NCT Etax No. of Send" + 1;
                        pSalesCreditMemo."NCT Etax Status" := pSalesCreditMemo."NCT Etax Status"::Fail;
                        pSalesCreditMemo."Have Email" := ltHaveEmail;
                        pSalesCreditMemo.Modify();
                    end;
                    CreateLogEtax(pSalesCreditMemo."NCT Etax Status");
                end;

            until pSalesCreditMemo.Next() = 0;


    end;

    /// <summary>
    /// CreateLogEtax.
    /// </summary>
    /// <param name="EtaxStatus">Enum "NCT Etax Status".</param>
    local procedure CreateLogEtax(EtaxStatus: Enum "NCT Etax Status")
    begin
        TempEtaxLog.reset();
        TempEtaxLog.SetCurrentKey("Document Type", "Entry No.");
        if TempEtaxLog.FindLast() then begin
            EtaxLog.Init();
            EtaxLog.TransferFields(TempEtaxLog, false);
            EtaxLog."Entry No." := EtaxLog.GetLastEntry();
            EtaxLog.Status := EtaxStatus;
            EtaxLog.Insert();
        end;
    end;

    /// <summary>
    /// SetDataEtax.
    /// </summary>
    /// <param name="EtaxValue">Text.</param>
    /// <param name="pComma">boolean.</param>
    /// <returns>Return value of type Text.</returns>
    local procedure SetDataEtax(EtaxValue: Text; pComma: boolean): Text
    begin
        EtaxValue := DelChr(EtaxValue, '=', '"''');
        if pComma then
            exit(StrSubstNo(DataTextLbl, EtaxValue) + ',')
        else
            exit(StrSubstNo(DataTextLbl, EtaxValue));
    end;

    /// <summary>
    /// CreatePDFReport.
    /// </summary>
    /// <param name="pDocumentType">Enum "Etax Document Type".</param>
    /// <param name="pNo">code[20].</param>
    /// <param name="pInstream">InStream.</param>
    /// <param name="pFileName">Text.</param>
    /// <param name="pEtaxType">Enum "NCT Etax Type".</param>
    local procedure CreatePDFReport(pDocumentType: Enum "Etax Document Type"; pNo: code[20]; pInstream: InStream; pFileName: Text; pEtaxType: Enum "NCT Etax Type")
    var
        SaleInvH: Record "Sales Invoice Header";
        SalesCN: Record "Sales Cr.Memo Header";
        SalesReceiptHeader: Record "NCT Billing Receipt Header";
        TempBlob: Codeunit "Temp Blob";
        SalesInvReport: Report "NCT ETax Sales Invoice";
        SalesCreditMemo: report "NCT ETax Sales Credit Memo";
        SalesReceipt: Report "NCT ETax Sales Receipt";
        ltTaxTypeEng: Enum "NCT Etax Type Eng";
        ltTaxTypeEngText: Text;
        ltDocumentOutStream: OutStream;
        ltDocumentInStream: InStream;
        ltEngIndex: Integer;
    begin
        ltEngIndex := pEtaxType.Ordinals.IndexOf(pEtaxType.AsInteger());
        ltTaxTypeEng.Names.Get(ltEngIndex, ltTaxTypeEngText);
        if SalesReceivablesSetup."NCT Etax Service Code" = SalesReceivablesSetup."NCT Etax Service Code"::S06 then begin
            if pDocumentType = pDocumentType::"Sales Invoice" then begin
                SaleInvH.Reset();
                SaleInvH.SetRange("No.", pNo);
                Clear(TempBlob);
                TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
                Clear(SalesInvReport);
                SalesInvReport.SetTableView(SaleInvH);
                SalesInvReport.setReportCaption(format(pEtaxType), ltTaxTypeEngText);
                SalesInvReport.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
                Clear(SalesInvReport);
                TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
            end;

            if pDocumentType = pDocumentType::"Sales Credit Memo" then begin
                SalesCN.Reset();
                SalesCN.SetRange("No.", pNo);
                Clear(TempBlob);
                TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
                Clear(SalesCreditMemo);
                SalesCreditMemo.SetTableView(SalesCN);
                SalesCreditMemo.setReportCaption(format(pEtaxType), ltTaxTypeEngText);
                SalesCreditMemo.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
                Clear(SalesCreditMemo);
                TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
            end;

            if pDocumentType = pDocumentType::"Sales Receipt" then begin
                SalesReceiptHeader.Reset();
                SalesReceiptHeader.SetRange("Document Type", SalesReceiptHeader."Document Type"::"Sales Receipt");
                SalesReceiptHeader.SetRange("No.", pNo);
                Clear(TempBlob);
                TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
                Clear(SalesReceipt);
                SalesReceipt.SetTableView(SalesReceiptHeader);
                SalesReceipt.setReportCaption(format(pEtaxType), ltTaxTypeEngText);
                SalesReceipt.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
                Clear(SalesReceipt);
                TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
            end;
        end;
        EntryNo := EntryNo + 1;
        TempEtaxLog.Init();
        TempEtaxLog."Entry No." := EntryNo;
        TempEtaxLog."Document Type" := pDocumentType;
        TempEtaxLog."Document No." := pNo;
        if SalesReceivablesSetup."NCT Etax Service Code" = SalesReceivablesSetup."NCT Etax Service Code"::S06 then
            TempEtaxLog."Last Pdf File".ImportStream(ltDocumentInStream, pFileName + '.pdf');
        TempEtaxLog."Last Text File".ImportStream(pInstream, pFileName + '.txt');
        TempEtaxLog."Etax Type" := COPYSTR(format(pEtaxType), 1, MaxStrLen(TempEtaxLog."Etax Type"));
        TempEtaxLog."Etax Type Code" := CopyStr(GetEnumValueName(pEtaxType), 1, MaxStrLen(TempEtaxLog."Etax Type Code"));
        TempEtaxLog."File Name" := COPYSTR(pFileName, 1, MaxStrLen(TempEtaxLog."File Name"));
        TempEtaxLog."Create By" := CopyStr(UserId, 1, 50);
        TempEtaxLog."Create DateTime" := CurrentDateTime();
        TempEtaxLog."NCT Error Msg." := COPYSTR(GetLastErrorText(), 1, MaxStrLen(TempEtaxLog."NCT Error Msg."));
        TempEtaxLog.Insert();
    end;

    [TryFunction]
    local procedure CallEtaxWebservice(pDocumentType: Enum "Etax Document Type"; pNo: code[20]; pfilename: text; pInstream: InStream; pEtaxType: Enum "NCT Etax Type")
    var
        TempBlob: Codeunit "Temp Blob";
        PayloadOutStream: OutStream;
        PayloadInStream: InStream;
        UrlAddress: Text[1024];
        DSVCHttpClient: HttpClient;
        ltHttpContent: HttpContent;
        HttpHeadersContent: HttpHeaders;
        ltHttpRequestMessage: HttpRequestMessage;
        ltHttpResponseMessage: HttpResponseMessage;
        ltJsonToken: JsonToken;
        ltjsonObject: JsonObject;
        CR: Char;
        LF: Char;
        NewLine, ResponseText : Text;
        DocumentInStream: InStream;
        PdfFileName, TextFileName : Text;
        TenantMedia: Record "Tenant Media";
        ltStatus, ltTransactionCode : text;
        ltLoopCheckStatusPC: Integer;

    begin
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CLEAR(ltLoopCheckStatusPC);
        CLEAR(PayloadOutStream);
        CLEAR(PayloadInStream);
        CLEAR(DocumentInStream);
        TextFileName := pfilename + '.txt';
        PdfFileName := pfilename + '.pdf';
        Clear(TempBlob);
        CreatePDFReport(pDocumentType, pNo, pInstream, pfilename, pEtaxType);
        TempEtaxLog.reset();
        if TempEtaxLog.FindFirst() then;
        if SalesReceivablesSetup."NCT Etax Service Code" = SalesReceivablesSetup."NCT Etax Service Code"::S06 then begin
            TenantMedia.GET(TempEtaxLog."Last Pdf File".Item(1));
            TenantMedia.CalcFields(Content);
            if TenantMedia.Content.HasValue then
                TenantMedia.Content.CreateInStream(DocumentInStream);
        end;
        UrlAddress := SalesReceivablesSetup."NCT Etax Service URL";
        ltHttpContent.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Clear();
        HttpHeadersContent.Add('Content-Type', 'multipart/form-data;boundary=D365BC');
        ltHttpRequestMessage.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Add('Authorization', 'Bearer ' + SalesReceivablesSetup."NCT Etax API Key");
        Clear(TempBlob);
        TempBlob.CreateOutStream(PayloadOutStream);

        PayloadOutStream.WriteText('--D365BC' + NewLine);
        PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerTaxId"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Tax ID" + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerBranchId"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Branch ID" + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        PayloadOutStream.WriteText('Content-Disposition: form-data; name="ServiceCode"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(Format(SalesReceivablesSetup."NCT Etax Service Code") + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        PayloadOutStream.WriteText('Content-Disposition: form-data; name="TextContent"; fileName="' + pfilename + '.txt"' + NewLine);
        PayloadOutStream.WriteText('Content-Type: application/octet-stream' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        CopyStream(PayloadOutStream, pInstream);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        if SalesReceivablesSetup."NCT Etax Service Code" = SalesReceivablesSetup."NCT Etax Service Code"::S06 then begin
            PayloadOutStream.WriteText('Content-Disposition: form-data; name="PDFContent"; fileName="' + pfilename + '.pdf"' + NewLine);
            PayloadOutStream.WriteText('Content-Type: application/octet-stream' + NewLine);
            PayloadOutStream.WriteText(NewLine);
            CopyStream(PayloadOutStream, DocumentInStream);
            PayloadOutStream.WriteText(NewLine);
            PayloadOutStream.WriteText('--D365BC--' + NewLine);
        end;

        TempBlob.CreateInStream(PayloadInStream);
        ltHttpContent.WriteFrom(PayloadInStream);
        ltHttpRequestMessage.Content := ltHttpContent;
        ltHttpRequestMessage.SetRequestUri(UrlAddress);
        ltHttpRequestMessage.Method := 'POST';
        DSVCHttpClient.Send(ltHttpRequestMessage, ltHttpResponseMessage);
        ltHttpResponseMessage.Content.ReadAs(ResponseText);
        if (ltHttpResponseMessage.IsSuccessStatusCode()) then begin
            ltJsonToken.ReadFrom(ResponseText);
            ltjsonObject := ltJsonToken.AsObject();
            ltStatus := SelectJsonTokenText(ltjsonObject, '$.status');
            ltTransactionCode := SelectJsonTokenText(ltjsonObject, '$.transactionCode');
            if UpperCase(ltStatus) = 'OK' then
                UpdateToLogAfterStatusSuccess(ltjsonObject, ltTransactionCode, pfilename)
            else
                if UpperCase(ltStatus) = 'ER' then begin
                    TempEtaxLog."NCT Error Msg." := COPYSTR(SelectJsonTokenText(ltjsonObject, '$.errorMessage'), 1, MaxStrLen(TempEtaxLog."NCT Error Msg."));
                    TempEtaxLog.Modify();
                    ERROR(ResponseText);
                end else
                    if UpperCase(ltStatus) = 'PC' then
                        while ltLoopCheckStatusPC < 3 do begin
                            Sleep(5000);
                            CLEAR(ltStatus);
                            if ResentCallEtaxWebservice(ltTransactionCode, ResponseText, ltjsonObject, ltStatus) then
                                if UpperCase(ltStatus) = 'OK' then begin
                                    UpdateToLogAfterStatusSuccess(ltjsonObject, ltTransactionCode, pfilename);
                                    ltLoopCheckStatusPC := 3;
                                end else
                                    ltLoopCheckStatusPC := ltLoopCheckStatusPC + 1
                            else
                                ERROR(ResponseText);
                        end;

        end else
            ERROR(ResponseText);

    end;

    [TryFunction]
    local procedure ResentCallEtaxWebservice(pTransactionCode: text; var pResponseText: text; var pjsonObject: JsonObject; var pStatus: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        PayloadOutStream: OutStream;
        PayloadInStream: InStream;
        UrlAddress: Text[1024];
        ltHttpClient: HttpClient;
        ltHttpContent: HttpContent;
        HttpHeadersContent: HttpHeaders;
        ltHttpRequestMessage: HttpRequestMessage;
        ltHttpResponseMessage: HttpResponseMessage;
        ltJsonToken: JsonToken;
        CR: Char;
        LF: Char;
        NewLine: Text;
    begin
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;

        CLEAR(PayloadOutStream);
        CLEAR(PayloadInStream);
        Clear(TempBlob);
        CLEAR(pResponseText);
        CLEAR(pjsonObject);
        CLEAR(pStatus);
        UrlAddress := SalesReceivablesSetup."Etax Get check status URL";
        ltHttpContent.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Clear();
        HttpHeadersContent.Add('Content-Type', 'multipart/form-data;boundary=D365BC');
        ltHttpRequestMessage.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Add('Authorization', 'Bearer ' + SalesReceivablesSetup."NCT Etax API Key");
        Clear(TempBlob);

        TempBlob.CreateOutStream(PayloadOutStream, TextEncoding::UTF8);

        PayloadOutStream.WriteText('--D365BC' + NewLine);
        PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerTaxId"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Tax ID" + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerBranchId"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Branch ID" + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        PayloadOutStream.WriteText('Content-Disposition: form-data; name="ServiceCode"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(Format(SalesReceivablesSetup."NCT Etax Service Code") + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);

        PayloadOutStream.WriteText('Content-Disposition: form-data; name="TransactionCode"' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(pTransactionCode + NewLine);
        PayloadOutStream.WriteText('--D365BC' + NewLine);


        TempBlob.CreateInStream(PayloadInStream, TextEncoding::UTF8);
        ltHttpContent.WriteFrom(PayloadInStream);

        ltHttpRequestMessage.Content := ltHttpContent;
        ltHttpRequestMessage.SetRequestUri(UrlAddress);
        ltHttpRequestMessage.Method := 'POST';
        ltHttpClient.Send(ltHttpRequestMessage, ltHttpResponseMessage);
        ltHttpResponseMessage.Content.ReadAs(pResponseText);
        if (ltHttpResponseMessage.IsSuccessStatusCode()) then begin
            ltJsonToken.ReadFrom(pResponseText);
            pjsonObject := ltJsonToken.AsObject();
            pStatus := SelectJsonTokenText(pjsonObject, '$.status');
            if UpperCase(pStatus) = 'ER' then begin
                pResponseText := SelectJsonTokenText(pjsonObject, '$.errorMessage');
                TempEtaxLog."NCT Error Msg." := COPYSTR(pResponseText, 1, MaxStrLen(TempEtaxLog."NCT Error Msg."));
                TempEtaxLog.Modify();
                ERROR(pResponseText);
            end;
        end else
            ERROR(pResponseText);

    end;

    local procedure UpdateToLogAfterStatusSuccess(pjsonObject: JsonObject; pTransactionCode: Text; pfilename: Text)
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        InStr: InStream;
        SelectDataDownload: array[2] of Text;
    begin
        CLEAR(InStr);
        CLEAR(SelectDataDownload);
        SelectDataDownload[1] := SelectJsonTokenText(pjsonObject, '$.xmlURL');
        if Client.Get(SelectDataDownload[1], Response) then begin
            Response.Content.ReadAs(InStr);
            Clear(TempEtaxLog."Last XML File");
            TempEtaxLog."Last XML File".ImportStream(InStr, pfilename + '.xml');
        end;
        CLEAR(InStr);
        SelectDataDownload[2] := SelectJsonTokenText(pjsonObject, '$.pdfURL');
        if Client.Get(SelectDataDownload[2], Response) then begin
            Response.Content.ReadAs(InStr);
            Clear(TempEtaxLog."Last PDF File");
            TempEtaxLog."Last PDF File".ImportStream(InStr, pfilename + '.pdf');
        end;
        TempEtaxLog."Transaction Code" := CopyStr(pTransactionCode, 1, MaxStrLen(TempEtaxLog."Transaction Code"));
        TempEtaxLog.Modify();
    end;
    /// <summary>
    /// GetEnumValueName.
    /// </summary>
    /// <param name="pEtaxType">Enum "NCT Etax Type".</param>
    /// <returns>Return value of type Text.</returns>
    local procedure GetEnumValueName(pEtaxType: Enum "NCT Etax Type"): Text;
    var
        ltIndex: Integer;
        ltName: Text;
    begin
        ltIndex := pEtaxType.Ordinals.IndexOf(pEtaxType.AsInteger());
        pEtaxType.Names.Get(ltIndex, ltName);
        exit(ltName);
    end;
    /// <summary>
    /// GetEnumEtaxPurposeValueName.
    /// </summary>
    /// <param name="pEtaxPurpose">Enum "NCT Etax Purpose".</param>
    /// <returns>Return value of type Text.</returns>
    local procedure GetEnumEtaxPurposeValueName(pEtaxPurpose: Enum "NCT Etax Purpose"): Text;
    var
        ltIndex: Integer;
        ltName: Text;
    begin
        ltIndex := pEtaxPurpose.Ordinals.IndexOf(pEtaxPurpose.AsInteger());
        pEtaxPurpose.Names.Get(ltIndex, ltName);
        exit(ltName);
    end;

    local procedure CheckService()
    begin
        TempEtaxLog.reset();
        TempEtaxLog.DeleteAll();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("NCT Etax API Key");
        SalesReceivablesSetup.TestField("NCT Etax Seller Branch ID");
        SalesReceivablesSetup.TestField("NCT Etax Seller Tax ID");
        SalesReceivablesSetup.TestField("NCT Etax Service URL");
        SalesReceivablesSetup.TestField("Etax Get check status URL");
        SalesReceivablesSetup.TestField("Etax Active");
    end;
    /// <summary>
    /// CreateToZipFile.
    /// </summary>
    /// <param name="pFileName">Text.</param>
    /// <param name="pDocumentNo">code[20].</param>
    local procedure CreateToZipFile(pFileName: Text; pDocumentNo: code[20])
    var
        TenantMedia: Record "Tenant Media";
        SalesSetup: Record "Sales & Receivables Setup";
        DataCompression: Codeunit "Data Compression";
        ltTempBlob: Codeunit "Temp Blob";
        FileCount: Integer;
        ZipName: Text;
        MaxLoop, iLoop : Integer;
        ZipFileOutstream: OutStream;
        ltInStream, ZipFileInstream : InStream;
    begin
        if (SalesSetup."NCT Etax Download PDF File") or (SalesSetup."NCT Etax Download Text File") then begin
            SalesSetup.GET();
            ZipName := pFileName + '.zip';
            FileCount := 0;
            TempEtaxLog.Reset();
            TempEtaxLog.SetRange("Document No.", pDocumentNo);
            if TempEtaxLog.FindSet() then begin
                DataCompression.CreateZipArchive();
                repeat
                    if SalesSetup."NCT Etax Download Text File" then begin
                        MaxLoop := TempEtaxLog."Last Text File".Count();
                        If MaxLoop <> 0 then
                            for iLoop := 1 to MaxLoop do
                                if TenantMedia.Get(TempEtaxLog."Last Text File".Item(iLoop)) then begin
                                    TenantMedia.Calcfields(Content);
                                    if TenantMedia.Content.HasValue() then begin
                                        TenantMedia.Content.CreateInStream(ltInStream);
                                        DataCompression.AddEntry(ltInStream, TempEtaxLog."File Name" + '.txt');
                                        FileCount += 1;
                                    end;
                                end;
                    end;
                    if SalesSetup."NCT Etax Download PDF File" then begin
                        MaxLoop := TempEtaxLog."Last Pdf File".Count();
                        If MaxLoop <> 0 then
                            for iLoop := 1 to MaxLoop do
                                if TenantMedia.Get(TempEtaxLog."Last Pdf File".Item(iLoop)) then begin
                                    TenantMedia.Calcfields(Content);
                                    if TenantMedia.Content.HasValue() then begin
                                        TenantMedia.Content.CreateInStream(ltInStream);
                                        DataCompression.AddEntry(ltInStream, TempEtaxLog."File Name" + '.pdf');
                                        FileCount += 1;
                                    end;
                                end;
                    end;
                    if SalesSetup."NCT Etax Download XML File" then begin
                        MaxLoop := TempEtaxLog."Last XML File".Count();
                        If MaxLoop <> 0 then
                            for iLoop := 1 to MaxLoop do
                                if TenantMedia.Get(TempEtaxLog."Last XML File".Item(iLoop)) then begin
                                    TenantMedia.Calcfields(Content);
                                    if TenantMedia.Content.HasValue() then begin
                                        TenantMedia.Content.CreateInStream(ltInStream);
                                        DataCompression.AddEntry(ltInStream, TempEtaxLog."File Name" + '.xml');
                                        FileCount += 1;
                                    end;
                                end;
                    end;
                until TempEtaxLog.Next() = 0;
                If FileCount > 0 then begin
                    ltTempBlob.CreateOutStream(ZipFileOutstream);
                    DataCompression.SaveZipArchive(ZipFileOutstream);
                    ltTempBlob.CreateInStream(ZipFileInstream);
                    DownloadFromStream(ZipFileInstream, '', '', '', ZipName);
                end;
                DataCompression.CloseZipArchive();
            end;
        end;
    end;

    /// <summary>
    /// SelectJsonTokenText.
    /// </summary>
    /// <param name="JsonObject">JsonObject.</param>
    /// <param name="Path">text.</param>
    /// <returns>Return value of type text.</returns>
    procedure SelectJsonTokenText(JsonObject: JsonObject; Path: text): text;
    var
        ltJsonToken: JsonToken;
        ltText: Text;
    begin

        if not JsonObject.SelectToken(Path, ltJsonToken) then
            exit('');
        if Format(ltJsonToken) <> '' then begin
            ltText := Format(ltJsonToken);
            if CopyStr(ltText, 1, 1) = '[' then begin
                ltText := delchr(ltText, '=', '[]');
                exit(ltText);
            end;
        end;
        if ltJsonToken.AsValue().IsNull then
            exit('');
        exit(ltJsonToken.asvalue().astext());
    end;

    var
        TempEtaxLog: Record "NCT Etax Log" temporary;
        EtaxLog: Record "NCT Etax Log";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CompanyInfo: Record "Company Information";
        DataTextLbl: Label '"%1"', Locked = true;
        NCTLCLFunction: Codeunit "NCT Function Center";
        VATText: Text[30];
        EntryNo: Integer;

}
