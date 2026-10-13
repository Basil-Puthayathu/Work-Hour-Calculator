import Foundation
import SwiftUI
import UIKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case xlsx, pdf, csv
    var id: String { rawValue }
    var title: String {
        switch self {
        case .xlsx: return "Excel (.xlsx)"
        case .pdf: return "PDF"
        case .csv: return "CSV"
        }
    }
    var fileExtension: String { rawValue }
}

struct ExportSnapshot {
    struct Row {
        let day: Int
        let ab: Entry
        let bl: Entry
        let ht: Entry
        let ch: Entry
        let hours: Double
    }
    let employee: String
    let monthName: String
    let year: Int
    let department: String
    let rows: [Row]
    let totals: WorkHoursCalculator.Totals
}

struct MonthExporter {
    func export(snapshot s: ExportSnapshot, format: ExportFormat) throws -> URL {
        let name = "Work Hours Record - \(s.monthName) \(s.year).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let data: Data
        switch format {
        case .csv: data = csv(s)
        case .pdf: data = pdf(s)
        case .xlsx: data = xlsx(s)
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    private func hours(_ v: Double) -> String { String(format: "%.2f", v) }

    // MARK: CSV
    private func csv(_ s: ExportSnapshot) -> Data {
        func esc(_ f: String) -> String {
            f.contains(",") || f.contains("\"") || f.contains("\n")
                ? "\"" + f.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : f
        }
        var lines = [
            "WORK HOURS RECORD",
            "Employee Name,\(esc(s.employee))",
            "Month,\(s.monthName)",
            "Year,\(s.year)",
            "Department,\(esc(s.department))",
            "",
            "Date,AB,BL,HT,CH,Total Hours"
        ]
        for r in s.rows {
            lines.append([String(r.day), r.ab.plainText, r.bl.plainText, r.ht.plainText, r.ch.plainText, hours(r.hours)]
                .map(esc).joined(separator: ","))
        }
        let t = s.totals
        lines.append(["TOTAL", Entry.plain(t.ab), Entry.plain(t.bl), Entry.plain(t.ht), Entry.plain(t.ch), hours(t.hours)]
            .joined(separator: ","))
        return Data(("\u{FEFF}" + lines.joined(separator: "\r\n")).utf8)
    }

    // MARK: PDF
    private func pdf(_ s: ExportSnapshot) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        return renderer.pdfData { ctx in
            ctx.beginPage()
            func draw(_ str: String, _ rect: CGRect, _ font: UIFont, _ align: NSTextAlignment = .left) {
                let p = NSMutableParagraphStyle()
                p.alignment = align
                (str as NSString).draw(in: rect, withAttributes: [
                    .font: font, .paragraphStyle: p, .foregroundColor: UIColor.black])
            }
            let regular = UIFont.systemFont(ofSize: 10)
            let bold = UIFont.boldSystemFont(ofSize: 10)

            draw("WORK HOURS RECORD", CGRect(x: 40, y: 36, width: 515, height: 28), .boldSystemFont(ofSize: 20))
            draw("Employee Name: \(s.employee)", CGRect(x: 40, y: 74, width: 515, height: 14), regular)
            draw("Month: \(s.monthName)     Year: \(s.year)", CGRect(x: 40, y: 90, width: 515, height: 14), regular)
            draw("Department: \(s.department)", CGRect(x: 40, y: 106, width: 515, height: 14), regular)

            let top: CGFloat = 132
            let rowH: CGFloat = 18
            let colW: CGFloat = 85
            func cell(_ text: String, col: Int, row: Int, font: UIFont) {
                draw(text, CGRect(x: 40 + CGFloat(col) * colW, y: top + CGFloat(row) * rowH + 3, width: colW, height: rowH),
                     font, .center)
            }
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(white: 0.88, alpha: 1).cgColor)
            cg.fill(CGRect(x: 40, y: top, width: colW * 6, height: rowH))
            for (i, h) in ["Date", "AB", "BL", "HT", "CH", "Total Hours"].enumerated() {
                cell(h, col: i, row: 0, font: bold)
            }
            cg.setStrokeColor(UIColor(white: 0.8, alpha: 1).cgColor)
            cg.setLineWidth(0.5)
            for (i, r) in s.rows.enumerated() {
                let row = i + 1
                let vals = [String(r.day), r.ab.plainText, r.bl.plainText, r.ht.plainText, r.ch.plainText, hours(r.hours)]
                for (c, v) in vals.enumerated() { cell(v, col: c, row: row, font: regular) }
                let y = top + CGFloat(row + 1) * rowH
                cg.move(to: CGPoint(x: 40, y: y)); cg.addLine(to: CGPoint(x: 40 + colW * 6, y: y)); cg.strokePath()
            }
            let tRow = s.rows.count + 1
            let t = s.totals
            let totals = ["TOTAL", Entry.plain(t.ab), Entry.plain(t.bl), Entry.plain(t.ht), Entry.plain(t.ch), hours(t.hours)]
            for (c, v) in totals.enumerated() { cell(v, col: c, row: tRow, font: bold) }
        }
    }

    // MARK: XLSX (minimal hand-built workbook, no external library)
    private func xlsx(_ s: ExportSnapshot) -> Data {
        func esc(_ t: String) -> String {
            t.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
        }
        func str(_ ref: String, _ t: String) -> String {
            "<c r=\"\(ref)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(esc(t))</t></is></c>"
        }
        func num(_ ref: String, _ v: Double) -> String { "<c r=\"\(ref)\"><v>\(v)</v></c>" }
        func entryCell(_ ref: String, _ e: Entry) -> String {
            switch e.kind {
            case .empty: return ""
            case .number: return num(ref, e.value)
            default: return str(ref, e.plainText)
            }
        }
        func row(_ n: Int, _ cells: String) -> String { "<row r=\"\(n)\">\(cells)</row>" }

        var rows: [String] = []
        rows.append(row(1, str("A1", "WORK HOURS RECORD")))
        rows.append(row(2, str("A2", "Employee Name") + str("B2", s.employee)))
        rows.append(row(3, str("A3", "Month") + str("B3", s.monthName)))
        rows.append(row(4, str("A4", "Year") + num("B4", Double(s.year))))
        rows.append(row(5, str("A5", "Department") + str("B5", s.department)))
        let headerRow = 7
        rows.append(row(headerRow, ["Date", "AB", "BL", "HT", "CH", "Total Hours"].enumerated()
            .map { str("\(["A", "B", "C", "D", "E", "F"][$0.offset])\(headerRow)", $0.element) }.joined()))
        let first = headerRow + 1
        for (i, r) in s.rows.enumerated() {
            let n = first + i
            rows.append(row(n, num("A\(n)", Double(r.day)) + entryCell("B\(n)", r.ab) + entryCell("C\(n)", r.bl)
                + entryCell("D\(n)", r.ht) + entryCell("E\(n)", r.ch) + num("F\(n)", r.hours)))
        }
        let last = first + s.rows.count - 1
        let tn = last + 1
        func sum(_ col: String, _ v: Double) -> String {
            "<c r=\"\(col)\(tn)\"><f>SUM(\(col)\(first):\(col)\(last))</f><v>\(v)</v></c>"
        }
        let t = s.totals
        rows.append(row(tn, str("A\(tn)", "TOTAL") + sum("B", t.ab) + sum("C", t.bl) + sum("D", t.ht)
            + sum("E", t.ch) + sum("F", t.hours)))

        let sheet = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><cols><col min="1" max="1" width="16" customWidth="1"/><col min="2" max="6" width="12" customWidth="1"/></cols><sheetData>\(rows.joined())</sheetData></worksheet>
        """
        var zip = ZipWriter()
        zip.add("[Content_Types].xml", """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>
        """)
        zip.add("_rels/.rels", """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>
        """)
        zip.add("xl/workbook.xml", """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Work Hours" sheetId="1" r:id="rId1"/></sheets></workbook>
        """)
        zip.add("xl/_rels/workbook.xml.rels", """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>
        """)
        zip.add("xl/worksheets/sheet1.xml", sheet)
        return zip.finish()
    }
}

/// Tiny "stored" (uncompressed) ZIP writer, enough for a valid .xlsx.
struct ZipWriter {
    private var body = Data()
    private var central = Data()
    private var count: UInt16 = 0

    private static let table: [UInt32] = (0..<256).map { (i: Int) -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
        return c
    }

    static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        for b in data { c = table[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return ~c
    }

    private func le16(_ v: UInt16) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
    private func le32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }

    mutating func add(_ name: String, _ text: String) {
        let content = Data(text.utf8)
        let nameData = Data(name.utf8)
        let crc = ZipWriter.crc32(content)
        let size = UInt32(content.count)
        let offset = UInt32(body.count)
        let dosDate: UInt16 = 33 // 1980-01-01

        body.append(le32(0x04034b50)); body.append(le16(20)); body.append(le16(0)); body.append(le16(0))
        body.append(le16(0)); body.append(le16(dosDate)); body.append(le32(crc))
        body.append(le32(size)); body.append(le32(size))
        body.append(le16(UInt16(nameData.count))); body.append(le16(0))
        body.append(nameData); body.append(content)

        central.append(le32(0x02014b50)); central.append(le16(20)); central.append(le16(20))
        central.append(le16(0)); central.append(le16(0)); central.append(le16(0)); central.append(le16(dosDate))
        central.append(le32(crc)); central.append(le32(size)); central.append(le32(size))
        central.append(le16(UInt16(nameData.count))); central.append(le16(0)); central.append(le16(0))
        central.append(le16(0)); central.append(le16(0)); central.append(le32(0))
        central.append(le32(offset)); central.append(nameData)
        count += 1
    }

    func finish() -> Data {
        var out = body
        let cdOffset = UInt32(body.count)
        out.append(central)
        out.append(le32(0x06054b50)); out.append(le16(0)); out.append(le16(0))
        out.append(le16(count)); out.append(le16(count))
        out.append(le32(UInt32(central.count))); out.append(le32(cdOffset)); out.append(le16(0))
        return out
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
