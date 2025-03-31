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
    
    func testBulletList_6() {
        let rawText = """
        - 123
          - ABC
          - DEF
        - 456
        """
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testQutote_1() {
        let rawText = """
        > Level 1
        > > Level 2
        > Level 1-1
        """
        let node = parser.parse(rawText)
        let a = converter.attributedStringFromMarkup(rawText)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        textView.attributedText = a
        print(a)
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    func testHeadingStyles() {
        // 測試所有標題級別
        let testCases = [
            "# 一級標題",
            "## 二級標題",
            "### 三級標題",
            "#### 四級標題",
            "##### 五級標題",
            "###### 六級標題"
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let attributedString = converter.attributedStringFromMarkup(testCase)
            let backToMarkup = converter.markupFromAttributedString(attributedString)
            
            // 驗證轉換後的文本
            XCTAssertEqual(backToMarkup, testCase)
            
            // 驗證字體大小
            if let font = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
                let expectedSizes: [CGFloat] = [28, 24, 20, 18, 16, 14]
                XCTAssertEqual(font.pointSize, expectedSizes[index])
                
                // 驗證字體是否為粗體
                XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.traitBold))
            } else {
                XCTFail("標題應該有字體屬性")
            }
            
            // 驗證段落樣式
            if let paragraphStyle = attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                XCTAssertEqual(paragraphStyle.paragraphSpacing, 10)
                XCTAssertEqual(paragraphStyle.paragraphSpacingBefore, 10)
            } else {
                XCTFail("標題應該有段落樣式")
            }
        }
    }
    
    func testMixedHeadingStyles() {
        let testCase = """
        # 一級標題
        正常文本
        ## 二級標題
        ### 三級標題
        正常文本
        """
        
        let attributedString = converter.attributedStringFromMarkup(testCase)
        let backToMarkup = converter.markupFromAttributedString(attributedString)
        
        XCTAssertEqual(backToMarkup, testCase)
    }
    
    func testInteractiveAttachments() {
        // 測試表格附件
        let tableData = [
            ["標題1", "標題2"],
            ["數據1", "數據2"]
        ]
        let tableView = InteractiveTableView(data: tableData)
        let tableAttachment = InteractiveAttachment(view: tableView)
        
        let tableAttributedString = NSAttributedString(attachment: tableAttachment)
        XCTAssertNotNil(tableAttributedString.attribute(.attachment, at: 0, effectiveRange: nil))
        
        // 測試提及附件
        let mentionView = MentionView(userId: "test123", displayName: "測試用戶") { _ in }
        let mentionAttachment = InteractiveAttachment(view: mentionView)
        
        let mentionAttributedString = NSAttributedString(attachment: mentionAttachment)
        XCTAssertNotNil(mentionAttributedString.attribute(.attachment, at: 0, effectiveRange: nil))
    }
    
//    func testMentionViewInteraction() {
//        var mentionTapped = false
//        let mentionView = MentionView(userId: "test123", displayName: "測試用戶") { _ in
//            mentionTapped = true
//        }
//        
//        // 模擬點擊
//        mentionView.subviews.first?.sendActions(for: .touchUpInside)
//        XCTAssertTrue(mentionTapped)
//    }
    
    func testInteractiveTableViewDataSource() {
        let testData = [
            ["標題1", "標題2"],
            ["數據1", "數據2"]
        ]
        let tableView = InteractiveTableView(data: testData)
        
        XCTAssertEqual(tableView.numberOfSections(in: tableView), 1)
        XCTAssertEqual(tableView.tableView(tableView, numberOfRowsInSection: 0), 2)
        
        let cell = tableView.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(cell.textLabel?.text, "標題1 | 標題2")
    }
}
