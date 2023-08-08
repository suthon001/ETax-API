/// <summary>
/// Codeunit NCT ETaxFunc (ID 80200).
/// </summary>
codeunit 80200 "NCT ETaxFunc"
{
    Permissions = tabledata "Sales Invoice Header" = rimd, tabledata "Sales Cr.Memo Header" = rimd, tabledata "NCT Billing Receipt Header" = rimd;

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
    procedure ETaxSalesReceip(var pSalesReceipt: Record "NCT Billing Receipt Header")
    var
        Cust: Record Customer;
        SalesBillingLine: Record "NCT Billing Receipt Line";
        NoSeries: Record "No. Series";
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
        TotalAmt: array[100] of Decimal;
        CR: Char;
        LF: Char;
    begin
        //CheckService();
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
                    NoSeries.GET(pSalesReceipt."No. Series");
                    NoSeries.TestField("NCT Etax Type Code");

                    Cust.GET(pSalesReceipt."Bill/Pay-to Cust/Vend No.");
                    if not PaymentTerms.GET(pSalesReceipt."Payment Terms Code") then
                        PaymentTerms.Init();
                    ltFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesReceipt."No.", pSalesReceipt."NCT Etax No. of Send" + 1) + '.txt';
                    ToFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesReceipt."No.", pSalesReceipt."NCT Etax No. of Send" + 1);
                    DataText := SetDataEtax('C', true);
                    DataText += SetDataEtax(DelChr(CompanyInfo."VAT Registration No.", '=', '-'), true);
                    VatBusSetup.get(pSalesReceipt."VAT Bus. Posting Group");
                    if not WHTBus.GET(pSalesReceipt."WHT Business Posting Group") then
                        WHTBus.Init();
                    if VatBusSetup."NCT Head Office" then
                        ltVatBranch := '00000'
                    else
                        ltVatBranch := VatBusSetup."NCT VAT Branch Code";
                    if ltVatBranch = '' then
                        ltVatBranch := '00000';

                    DataText += SetDataEtax(ltVatBranch, true);
                    DataText += SetDataEtax(ltFileName, false);
                    EtaxData := DataText + NewLine;

                    DataText := SetDataEtax('H', true); //1
                    DataText += SetDataEtax(GetEnumValueName(NoSeries."NCT Etax Type Code"), true); //2
                    DataText += SetDataEtax(format(NoSeries."NCT Etax Type Code"), true); // 3
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
                            DataText += SetDataEtax(format(SalesBillingLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true); //11
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
                            DataText += SetDataEtax(format(SalesBillingLine."Vat %", 0, '<Precision,2:2><Standard Format,0>'), true); //22
                            DataText += SetDataEtax(format(SalesBillingLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesBillingLine.Amount - SalesBillingLine."Amount Exclude Vat", 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(format(SalesBillingLine.Amount - SalesBillingLine."Amount Exclude Vat", 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesBillingLine."Amount Exclude Vat", 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesBillingLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
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
                    DataText += SetDataEtax(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
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
                    DataText += SetDataEtax(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                    DataText := SetDataEtax('T', True);
                    DataText += SetDataEtax('1', false);
                    EtaxData := EtaxData + DataText;
                    ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
                    ltOutStream.WriteText(EtaxData);
                    ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
                    if CallEtaxWebservice(2, pSalesReceipt."No.", ToFileName, EtaxData, ltInStream, Format(NoSeries."NCT Etax Type Code")) then begin
                        pSalesReceipt."NCT Etax Send to E-Tax" := true;
                        pSalesReceipt."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                        pSalesReceipt."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                        pSalesReceipt."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesReceipt."NCT Etax No. of Send" := pSalesReceipt."NCT Etax No. of Send" + 1;
                        pSalesReceipt."NCT Etax Status" := pSalesReceipt."NCT Etax Status"::Completely;
                        pSalesReceipt.Modify();
                    end else begin
                        pSalesReceipt."NCT Etax Send to E-Tax" := false;
                        pSalesReceipt."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                        pSalesReceipt."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                        pSalesReceipt."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesReceipt."NCT Etax No. of Send" := pSalesReceipt."NCT Etax No. of Send" + 1;
                        pSalesReceipt."NCT Etax Status" := pSalesReceipt."NCT Etax Status"::Fail;
                        pSalesReceipt.Modify();
                    end;
                    CreateLogEtax(pSalesReceipt."NCT Etax Status");
                end;
            until pSalesReceipt.Next() = 0;

        CreateToZipFile(StrSubstNo('SalesReceipt_%1', Format(Today, 0, '<Day,2><Month,2><Year4>')));
    end;

    /// <summary>
    /// ETaxSalesInvoice.
    /// </summary>
    /// <param name="pSalesInvHeader">Record "Sales Invoice Header".</param>
    procedure ETaxSalesInvoice(var pSalesInvHeader: Record "Sales Invoice Header")
    var
        Cust: Record Customer;
        SalesInvoiceLine: Record "Sales Invoice Line";
        NoSeries: Record "No. Series";
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
        CR: Char;
        LF: Char;
    begin
        //CheckService();
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
                    NoSeries.GET(pSalesInvHeader."No. Series");
                    NoSeries.TestField("NCT Etax Type Code");

                    Cust.GET(pSalesInvHeader."Sell-to Customer No.");
                    if not PaymentTerms.GET(pSalesInvHeader."Payment Terms Code") then
                        PaymentTerms.Init();
                    ltFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesInvHeader."No.", pSalesInvHeader."NCT Etax No. of Send" + 1) + '.txt';
                    ToFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesInvHeader."No.", pSalesInvHeader."NCT Etax No. of Send" + 1);
                    DataText := SetDataEtax('C', true);
                    DataText += SetDataEtax(DelChr(CompanyInfo."VAT Registration No.", '=', '-'), true);
                    VatBusSetup.get(pSalesInvHeader."VAT Bus. Posting Group");
                    if not WHTBus.GET(pSalesInvHeader."NCT WHT Business Posting Group") then
                        WHTBus.Init();
                    if VatBusSetup."NCT Head Office" then
                        ltVatBranch := '00000'
                    else
                        ltVatBranch := VatBusSetup."NCT VAT Branch Code";
                    if ltVatBranch = '' then
                        ltVatBranch := '00000';

                    DataText += SetDataEtax(ltVatBranch, true);
                    DataText += SetDataEtax(ltFileName, false);
                    EtaxData := DataText + NewLine;

                    DataText := SetDataEtax('H', true); //1
                    DataText += SetDataEtax(GetEnumValueName(NoSeries."NCT Etax Type Code"), true); //2
                    DataText += SetDataEtax(format(NoSeries."NCT Etax Type Code"), true); // 3
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
                            DataText += SetDataEtax(format(SalesInvoiceLine."Unit Price", 0, '<Precision,2:2><Standard Format,0>'), true); //11
                            DataText += SetDataEtax(CurrencyCode, true); //12
                            DataText += SetDataEtax('', true); //13
                            DataText += SetDataEtax(format(SalesInvoiceLine."Line Discount Amount", 0, '<Precision,2:2><Standard Format,0>'), true); //14
                            if SalesInvoiceLine."Line Discount Amount" <> 0 then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true); //16
                            DataText += SetDataEtax('', true); //17
                            DataText += SetDataEtax(format(SalesInvoiceLine.Quantity), true); //18
                            DataText += SetDataEtax(SalesInvoiceLine."Unit of Measure Code", true); //19
                            DataText += SetDataEtax(format(SalesInvoiceLine."Qty. per Unit of Measure", 0, '<Precision,2:2><Standard Format,0>'), true); //20
                            DataText += SetDataEtax('VAT', true); //21
                            DataText += SetDataEtax(format(SalesInvoiceLine."VAT %", 0, '<Precision,2:2><Standard Format,0>'), true); //22
                            DataText += SetDataEtax(format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesInvoiceLine."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), true);
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
                    DataText += SetDataEtax(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
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
                    DataText += SetDataEtax(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                    DataText := SetDataEtax('T', True);
                    DataText += SetDataEtax('1', false);
                    EtaxData := EtaxData + DataText;
                    ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
                    ltOutStream.WriteText(EtaxData);
                    ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
                    if CallEtaxWebservice(0, pSalesInvHeader."No.", ToFileName, EtaxData, ltInStream, Format(NoSeries."NCT Etax Type Code")) then begin
                        pSalesInvHeader."NCT Etax Send to E-Tax" := true;
                        pSalesInvHeader."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                        pSalesInvHeader."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                        pSalesInvHeader."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesInvHeader."NCT Etax No. of Send" := pSalesInvHeader."NCT Etax No. of Send" + 1;
                        pSalesInvHeader."NCT Etax Status" := pSalesInvHeader."NCT Etax Status"::Completely;
                        pSalesInvHeader.Modify();
                    end else begin
                        pSalesInvHeader."NCT Etax Send to E-Tax" := false;
                        pSalesInvHeader."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                        pSalesInvHeader."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                        pSalesInvHeader."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesInvHeader."NCT Etax No. of Send" := pSalesInvHeader."NCT Etax No. of Send" + 1;
                        pSalesInvHeader."NCT Etax Status" := pSalesInvHeader."NCT Etax Status"::Fail;
                        pSalesInvHeader.Modify();
                    end;
                    CreateLogEtax(pSalesInvHeader."NCT Etax Status");
                end;
            until pSalesInvHeader.Next() = 0;

        CreateToZipFile(StrSubstNo('SalesInvoice_%1', Format(Today, 0, '<Day,2><Month,2><Year4>')));
    end;
    /// <summary>
    /// ETaxSalesCreditMemo.
    /// </summary>
    /// <param name="pSalesCreditMemo">VAR Record "Sales Cr.Memo Header".</param>
    procedure ETaxSalesCreditMemo(var pSalesCreditMemo: Record "Sales Cr.Memo Header")
    var
        Cust: Record Customer;
        SalesCreditMemoLine: Record "Sales Cr.Memo Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        NoSeries: Record "No. Series";
        Itemcategory: Record "Item Category";
        PaymentTerms: Record "Payment Terms";
        ltItem: Record Item;
        WHTBus: Record "NCT WHT Business Posting Group";
        ltTempblob: Codeunit "Temp Blob";
        ltOutStream: OutStream;
        ltInStream: InStream;
        ltFilenameLbl: Label 'SalesCreditMemo_%1_%2_%3';
        ltFileName, ToFileName : Text;
        DataText, ltVatBranch, ltCustVatBranch, EtaxData, NewLine : Text;
        CurrencyCode: Code[10];
        TotalSalesCreditLine, LineNo : Integer;
        ltApplyDocID: Code[50];
        VatPer, TotalLineDisAmt : Decimal;
        TotalAmt: array[100] of Decimal;
        CR: Char;
        LF: Char;
    begin
        //CheckService();
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
                    NoSeries.GET(pSalesCreditMemo."No. Series");
                    NoSeries.TestField("NCT Etax Type Code");
                    if pSalesCreditMemo."Applies-to Doc. No." <> '' then
                        ltApplyDocID := pSalesCreditMemo."Applies-to Doc. No."
                    else
                        ltApplyDocID := pSalesCreditMemo."NCT Applies-to ID";
                    if ltApplyDocID = '' then
                        ltApplyDocID := pSalesCreditMemo."External Document No.";

                    Cust.GET(pSalesCreditMemo."Sell-to Customer No.");
                    if not PaymentTerms.GET(pSalesCreditMemo."Payment Terms Code") then
                        PaymentTerms.Init();
                    ltFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesCreditMemo."No.", pSalesCreditMemo."NCT Etax No. of Send" + 1) + '.txt';
                    ToFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesCreditMemo."No.", pSalesCreditMemo."NCT Etax No. of Send" + 1);
                    DataText := SetDataEtax('C', true);
                    DataText += SetDataEtax(DelChr(CompanyInfo."VAT Registration No.", '=', '-'), true);
                    VatBusSetup.get(pSalesCreditMemo."VAT Bus. Posting Group");
                    if not WHTBus.GET(pSalesCreditMemo."NCT WHT Business Posting Group") then
                        WHTBus.Init();
                    if VatBusSetup."NCT Head Office" then
                        ltVatBranch := '00000'
                    else
                        ltVatBranch := VatBusSetup."NCT VAT Branch Code";
                    if ltVatBranch = '' then
                        ltVatBranch := '00000';

                    DataText += SetDataEtax(ltVatBranch, true);
                    DataText += SetDataEtax(ltFileName, false);
                    EtaxData := DataText + NewLine;

                    DataText := SetDataEtax('H', true); //1
                    DataText += SetDataEtax(GetEnumValueName(NoSeries."NCT Etax Type Code"), true); //2
                    DataText += SetDataEtax(format(NoSeries."NCT Etax Type Code"), true); // 3
                    DataText += SetDataEtax(pSalesCreditMemo."No.", true); //4
                    DataText += SetDataEtax(format(pSalesCreditMemo."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true); //5
                    DataText += SetDataEtax(GetEnumEtaxPurposeValueName(pSalesCreditMemo."NCT Etax Purpose"), true);//6
                    DataText += SetDataEtax(pSalesCreditMemo."NCT Etax Purpose Remark", true);//7
                    DataText += SetDataEtax(ltApplyDocID, true);//8
                    DataText += SetDataEtax(format(pSalesCreditMemo."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);//9
                    DataText += SetDataEtax('T02', true);//10
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
                            DataText += SetDataEtax(format(SalesCreditMemoLine."Unit Price", 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine."Line Discount Amount", 0, '<Precision,2:2><Standard Format,0>'), true);
                            if SalesCreditMemoLine."Line Discount Amount" <> 0 then
                                DataText += SetDataEtax(CurrencyCode, true)
                            else
                                DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine.Quantity), true);
                            DataText += SetDataEtax(SalesCreditMemoLine."Unit of Measure Code", true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine."Qty. per Unit of Measure", 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax('VAT', true); //21
                            DataText += SetDataEtax(format(SalesCreditMemoLine."VAT %", 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine."Amount Including VAT" - SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax('', true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine."Amount Including VAT" - SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                            DataText += SetDataEtax(CurrencyCode, true);
                            DataText += SetDataEtax(format(SalesCreditMemoLine."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), true);
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
                    DataText += SetDataEtax(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(PaymentTerms.Description, true);
                    DataText += SetDataEtax(format(pSalesCreditMemo."Due Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);
                    DataText += SetDataEtax(format(TotalAmt[99], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[100], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                    DataText := SetDataEtax('T', True);
                    DataText += SetDataEtax('1', false);
                    EtaxData := EtaxData + DataText;
                    ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
                    ltOutStream.WriteText(EtaxData);
                    ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
                    if CallEtaxWebservice(1, pSalesCreditMemo."No.", ToFileName, EtaxData, ltInStream, Format(NoSeries."NCT Etax Type Code")) then begin
                        pSalesCreditMemo."NCT Etax Send to E-Tax" := true;
                        pSalesCreditMemo."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                        pSalesCreditMemo."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                        pSalesCreditMemo."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesCreditMemo."NCT Etax No. of Send" := pSalesCreditMemo."NCT Etax No. of Send" + 1;
                        pSalesCreditMemo."NCT Etax Status" := pSalesCreditMemo."NCT Etax Status"::Completely;
                        pSalesCreditMemo.Modify();
                    end else begin
                        pSalesCreditMemo."NCT Etax Send to E-Tax" := false;
                        pSalesCreditMemo."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                        pSalesCreditMemo."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                        pSalesCreditMemo."NCT Etax Send DateTime" := CurrentDateTime();
                        pSalesCreditMemo."NCT Etax No. of Send" := pSalesCreditMemo."NCT Etax No. of Send" + 1;
                        pSalesCreditMemo."NCT Etax Status" := pSalesCreditMemo."NCT Etax Status"::Fail;
                        pSalesCreditMemo.Modify();
                    end;
                    CreateLogEtax(pSalesCreditMemo."NCT Etax Status");
                end;
            until pSalesCreditMemo.Next() = 0;

        CreateToZipFile(StrSubstNo('SalesCreditMemo_%1', Format(Today, 0, '<Day,2><Month,2><Year4>')));
    end;

    /// <summary>
    /// CreateLogEtax.
    /// </summary>
    /// <param name="EtaxStatus">Enum "NCT Etax Status".</param>
    local procedure CreateLogEtax(EtaxStatus: Enum "NCT Etax Status")
    begin
        TempEtaxLog.reset();
        TempEtaxLog.SetCurrentKey("Entry No.");
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
    /// <param name="pDocumentType">Option "Sales Invoice","Sales Credit Memo","Sales Receipt".</param>
    /// <param name="pNo">code[30].</param>
    local procedure CreatePDFReport(pDocumentType: Option "Sales Invoice","Sales Credit Memo","Sales Receipt"; pNo: code[20]; pInstream: InStream; pFileName: Text; pEtaxType: Text)
    var
        SaleInvH: Record "Sales Invoice Header";
        SalesCN: Record "Sales Cr.Memo Header";
        SalesReceiptHeader: Record "NCT Billing Receipt Header";
        TempBlob: Codeunit "Temp Blob";
        SalesInvReport: Report "NCT Sales Invoice (Post)";
        SalesCreditMemo: report "NCT Sales Credit Memo (Post)";
        SalesReceipt: Report "NCT Sales Receipt";
        ltDocumentOutStream: OutStream;
        ltDocumentInStream: InStream;
    begin
        if pDocumentType = pDocumentType::"Sales Invoice" then begin
            SaleInvH.Reset();
            SaleInvH.SetRange("No.", pNo);
            Clear(TempBlob);
            TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
            Clear(SalesInvReport);
            SalesInvReport.SetTableView(SaleInvH);
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
            SalesReceipt.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
            Clear(SalesReceipt);
            TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
        end;

        EntryNo := EntryNo + 1;
        TempEtaxLog.Init();
        TempEtaxLog."Entry No." := EntryNo;
        TempEtaxLog."Document Type" := pDocumentType;
        TempEtaxLog."Document No." := pNo;
        TempEtaxLog."Last Pdf File".ImportStream(ltDocumentInStream, pFileName + '.pdf');
        TempEtaxLog."Last Text File".ImportStream(pInstream, pFileName + '.txt');
        TempEtaxLog."Etax Type" := COPYSTR(pEtaxType, 1, 250);
        TempEtaxLog."File Name" := COPYSTR(pFileName, 1, 100);
        TempEtaxLog."Create By" := CopyStr(UserId, 1, 50);
        TempEtaxLog."Create DateTime" := CurrentDateTime();
        TempEtaxLog.Insert();
    end;

    [TryFunction]
    local procedure CallEtaxWebservice(pDocumentType: Option "Sales Invoice","Sales Credit Memo","Sales Receipt"; pNo: code[20]; pfilename: text; pTextData: text; pInstream: InStream; pEtaxType: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        PayloadOutStream: OutStream;
        PayloadInStream: InStream;
        UrlAddress: Text[1024];
        DSVCHttpClient: HttpClient;
        DSVCHttpContent: HttpContent;
        HttpHeadersContent: HttpHeaders;
        DSVCHttpRequestMessage: HttpRequestMessage;
        DSVCHttpResponseMessage: HttpResponseMessage;
        CR: Char;
        LF: Char;
        NewLine, ToBase64_pdf, ToBase64_txt, ResponseText : Text;
        SelectDataDownload: array[2] of Text;
        DocumentInStream: InStream;
        DocumentOutStream: OutStream;
        PdfFileName, TextFileName : Text;
        TenantMedia: Record "Tenant Media";

    begin
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CLEAR(SelectDataDownload);
        CLEAR(PayloadOutStream);
        CLEAR(PayloadInStream);
        Clear(ToBase64_pdf);
        CLEAR(ToBase64_txt);
        TextFileName := pfilename + '.txt';
        PdfFileName := pfilename + '.pdf';

        ToBase64_txt := Base64Convert.ToBase64(pTextData);



        CreatePDFReport(pDocumentType, pNo, pInstream, pfilename, pEtaxType);


        Clear(TempBlob);
        TempEtaxLog.reset();
        TenantMedia.GET(TempEtaxLog."Last Text File".Item(1));
        TenantMedia.CalcFields(Content);
        if TenantMedia.Content.HasValue then begin
            TenantMedia.Content.CreateInStream(DocumentInStream);
            TempBlob.CreateOutStream(DocumentOutStream);
            CopyStream(DocumentOutStream, DocumentInStream);
            ToBase64_pdf := Base64Convert.ToBase64(DocumentInStream);
        end;




        // UrlAddress := SalesReceivablesSetup."NCT Etax Service URL";
        // DSVCHttpContent.GetHeaders(HttpHeadersContent);

        // HttpHeadersContent.Clear();
        // HttpHeadersContent.Add('Content-Type', 'multipart/form-data;boundary=D365BC');
        // Clear(TempBlob);
        // TempBlob.CreateOutStream(PayloadOutStream);

        // PayloadOutStream.WriteText('--D365BC' + NewLine);
        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerTaxId"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Tax ID" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerBranchId"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Branch ID" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="UserCode"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax User Code" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="AccessKey"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Access Key" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="ServiceCode"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(Format(SalesReceivablesSetup."NCT Etax Service Code") + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="APIKey"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax API Key" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);


        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="TextContent"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(ToBase64_txt + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);


        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="PDFContent"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(ToBase64_pdf + NewLine);
        // PayloadOutStream.WriteText('--D365BC--' + NewLine);

        // TempBlob.CreateInStream(PayloadInStream);

        // DSVCHttpContent.WriteFrom(PayloadInStream);
        // DSVCHttpRequestMessage.Content := DSVCHttpContent;
        // DSVCHttpRequestMessage.SetRequestUri(UrlAddress);
        // DSVCHttpRequestMessage.Method := 'POST';
        // DSVCHttpClient.Send(DSVCHttpRequestMessage, DSVCHttpResponseMessage);
        // DSVCHttpResponseMessage.Content.ReadAs(ResponseText);
        // //  SelectDataDownload[1] := SelectStr(3, ResponseText); //xmlfile
        // if StrPos(ResponseText, 'pdfURL') <> 0 then begin
        //     DownloadFromStream(PayloadInStream, '', '', '', pfilename);
        //     ResponseText := DelChr(ResponseText, '=', '{}');
        //     // SelectDataDownload[2] := SelectStr(4, ResponseText); //pdffile
        //     // SelectDataDownload[2] := DELChr(COPYSTR(SelectDataDownload[2], 10), '=', '"');
        //     // Hyperlink(SelectDataDownload[2]);
        // end else
        //     Message(ResponseText);


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
        SalesReceivablesSetup.TestField("NCT Etax Access Key");
        SalesReceivablesSetup.TestField("NCT Etax API Key");
        SalesReceivablesSetup.TestField("NCT Etax Seller Branch ID");
        SalesReceivablesSetup.TestField("NCT Etax Seller Tax ID");
        SalesReceivablesSetup.TestField("NCT Etax Service Code");
        SalesReceivablesSetup.TestField("NCT Etax User Code");
        SalesReceivablesSetup.TestField("NCT Etax Service URL");

    end;

    local procedure CreateToZipFile(pFileName: Text)
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
        SalesSetup.GET();
        ZipName := pFileName + '.zip';
        FileCount := 0;
        if (SalesSetup."NCT Etax Download PDF File") or (SalesSetup."NCT Etax Download Text File") then begin
            TempEtaxLog.Reset();
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


    var
        TempEtaxLog: Record "NCT Etax Log" temporary;
        EtaxLog: Record "NCT Etax Log";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CompanyInfo: Record "Company Information";
        VatBusSetup: Record "VAT Business Posting Group";
        DataTextLbl: Label '"%1"', Locked = true;
        NCTLCLFunction: Codeunit "NCT Function Center";
        VATText: Text[30];
        EntryNo: Integer;

}
