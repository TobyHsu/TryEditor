import XCTest
@testable import TMarkupParser

final class TMarkupParserTests: XCTestCase {
    var parser: MarkupParser!
    var converter: MarkupConverter!
    
    override func setUp() {
        super.setUp()
        parser = MarkupParser()
        converter = MarkupConverter(parser: parser)
    }
    
    override func tearDown() {
        parser = nil
        converter = nil
        super.tearDown()
    }
    
    // MARK: - 基本样式测试
    func testBoldStyle() {
        let testCases = [
            "**測試**",
            "***測試***",
            "****測試****"
        ]
        
        for testCase in testCases {
            let attributedString = converter.attributedStringFromMarkup(testCase)
            let backToMarkup = converter.markupFromAttributedString(attributedString)
            print(testCase)
            XCTAssertEqual(attributedString.string, "測試")
            XCTAssertEqual(backToMarkup, "**測試**")
        }
    }
    
    func testMixCase() {
        let rawText = "**12**{{font color=\"#FF0000\"}}3{{/font}}{{font color=\"#FF0000\"}}~~4~~{{/font}}~~5~~67"
        let a = NSMutableAttributedString(string: "1234567")
        a.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: NSRange(location: 0, length: 2))
        a.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 2, length: 2))
        a.addAttribute(.font, value: UIFont.systemFont(ofSize: 20), range: NSRange(location: 3, length: 1))
        a.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 3, length: 2))
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testBulletList() {
        let rawText = """
        - {{font color="#FF0000"}}**项目符号列表项1**{{/font}}
        - _**项目符号列表项2**_
        """
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testBulletList_2() {
        let rawText = """
        - **1234**
        5678
        """
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testBulletList_3() {
        let rawText = """
        - **1234**
        """
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testBulletList_4() {
        let rawText = """
        - 1234
        5678
        """
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testBulletList_5() {
        let rawText = """
        - 1234
          - **abc**
          - _def_
        - 5678
        """
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
}
