/// <summary>
/// Enum NCT Etax Etax Purpose (ID 80203).
/// </summary>
enum 80203 "NCT Etax Purpose"
{
    Extensible = true;
    value(0; " ") { Caption = ' '; }
    value(1; "CDNG01") { Caption = 'ลดราคาสินค้าที่ขาย (สินค้าผิดข้อกำหนดที่ตกลงกัน)'; }
    value(2; "CDNG02") { Caption = 'สินค้าชำรุดเสียหาย'; }
    value(3; "CDNG03") { Caption = 'สินค้าขาดจำนวนตามที่ตกลงซื้อขาย'; }
    value(4; "CDNG04") { Caption = 'คำนวณราคาสินค้าผิดพลาดสูงกว่าที่เป็นจริง'; }
    value(5; "CDNG05") { Caption = 'รับคืนสินค้า'; }
    value(6; "CDNG99") { Caption = 'เหตุอื่น (ระบุสาเหตุสินค้า)'; }
    value(7; "CDNS01") { Caption = 'ลดราคาค่าบริการ (บริการผิดข้อกำหนดที่ตกลงกัน)'; }
    value(8; "CDNS02") { Caption = 'ค่าบริการขาดจำนวน'; }
    value(9; "CDNS03") { Caption = 'คำนวณราคาค่าบริการผิดพลาดสูงกว่าที่เป็นจริง'; }
    value(10; "CDNS04") { Caption = 'บอกเลิกสัญญาบริการ'; }
    value(11; "CDNS99") { Caption = 'เหตุอื่น (ระบุสาเหตุค่าบริการ)'; }
}
