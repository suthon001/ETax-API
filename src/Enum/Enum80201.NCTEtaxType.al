/// <summary>
/// Enum NCT Etax Type (ID 80201).
/// </summary>
enum 80201 "NCT Etax Type"
{
    Extensible = true;
    value(0; " ") { Caption = ' '; }
    value(1; "T01") { Caption = 'ใบรับ (ใบเสร็จรับเงิน)'; }
    value(2; "T02") { Caption = 'ใบแจ้งหนี้/ใบกำกับภาษี'; }
    value(3; "T03") { Caption = 'ใบเสร็จรับเงิน/ใบกำกับภาษี'; }
    value(4; "T04") { Caption = 'ใบส่งของ/ใบกำกับภาษี'; }
    value(5; "T05") { Caption = 'ใบกำกำกับภาษีแบบย่อ'; }
    value(6; "80") { Caption = 'ใบเพิ่มหนี้'; }
    value(7; "81") { Caption = 'ใบลดหนี้'; }
    value(8; "380") { Caption = 'ใบแจ้งหนี้'; }
    value(9; "388") { Caption = 'ใบกำกับภาษี'; }
}
