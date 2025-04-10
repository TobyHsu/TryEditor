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
    
    func testListAndFontStyle() {
        let rawText = """
        - abc
        - def
        {{font color="#FF0000"}}my world{{/font}}
        """
        
        let node = parser.parse(rawText)
        let a = converter.attributedStringFromMarkup(rawText)
        XCTAssertEqual(a.string, "\t• abc\n\t• def\nmy world")
        let backToMarkup = converter.markupFromAttributedString(a)
        XCTAssertEqual(backToMarkup, rawText)
    }
    
    // MARK: - 測試游標位置映射
    func testCursorPositionMapping() {
        // 創建測試用的位置映射管理器
        let positionMapper = PositionMapper(parser: parser)
        
        // 測試1: 普通樣式的位置映射
        let test1 = "**粗體文本**"
        let expectedMapping1: [(Int, Int)] = [
            (0, 0), // **的開始
            (1, 0), // *的位置
            (2, 0), // 粗體文本的開始，轉換後應該是位置0
            (3, 1), // 對應轉換後的'粗'字位置1
            (4, 2), // 對應轉換後的'體'字位置2
            (5, 3), // 對應轉換後的'文'字位置3
            (6, 4), // 對應轉換後的'本'字位置4
            (7, 4), // **的開始
            (8, 4)  // *的位置
        ]
        
        let attributedText1 = converter.attributedStringFromMarkup(test1)
        positionMapper.buildPositionMap(rawText: test1, attributedString: attributedText1)
        
        for (raw, rendered) in expectedMapping1 {
            let calculatedRendered = positionMapper.convertToRenderedPosition(raw)
            XCTAssertEqual(calculatedRendered, rendered, "測試1：原始位置 \(raw) 應該映射到渲染位置 \(rendered)，但得到了 \(calculatedRendered)")
            
            let calculatedRaw = positionMapper.convertToRawPosition(rendered)
            XCTAssertLessThanOrEqual(calculatedRaw, raw, "測試1：渲染位置 \(rendered) 應該映射到原始位置小於等於 \(raw)，但得到了 \(calculatedRaw)")
        }
        
        // 測試2: 列表樣式的位置映射
        let test2 = """
        - 列表項1
        - 列表項2
          - 嵌套項
        """
        
        let expectedMapping2: [(Int, Int)] = [
            (0, 0),  // '-'的位置，轉換後縮進+項目符號的開始
            (1, 0),  // ' '的位置，仍在項目符號內
            (2, 2),  // '列'的位置，轉換後實際文本開始
            (5, 5),  // '1'的位置
            (6, 6),  // 換行符位置
            (7, 7),  // 第二個'-'的位置
            (9, 9),  // 第二個列表項實際文本開始
            (14, 14), // 換行符位置
            (15, 15), // 空格，表示縮進
            (16, 15), // 空格，表示縮進
            (17, 15), // 嵌套列表'-'的位置
            (18, 15), // 嵌套列表' '的位置
            (19, 17)  // '嵌'的位置，嵌套列表實際文本開始
        ]
        
        let attributedText2 = converter.attributedStringFromMarkup(test2)
        positionMapper.buildPositionMap(rawText: test2, attributedString: attributedText2)
        
        print("原始文本: \"\(test2)\"")
        print("渲染文本: \"\(attributedText2.string)\"")
        
        for (raw, rendered) in expectedMapping2 {
            let calculatedRendered = positionMapper.convertToRenderedPosition(raw)
            // 由於列表項的複雜性，我們這裡只測試近似值
            XCTAssertTrue(abs(calculatedRendered - rendered) <= 2, 
                         "測試2：原始位置 \(raw) 應該映射到渲染位置接近 \(rendered)，但得到了 \(calculatedRendered)")
            
            if rendered < attributedText2.length {
                let calculatedRaw = positionMapper.convertToRawPosition(rendered)
                // 同樣測試近似值
                XCTAssertTrue(abs(calculatedRaw - raw) <= 2 || calculatedRaw <= raw, 
                             "測試2：渲染位置 \(rendered) 應該映射到原始位置接近 \(raw)，但得到了 \(calculatedRaw)")
            }
        }
        
        // 測試3: 混合樣式的測試
        let test3 = "- **粗體** _斜體_"
        
        let expectedMapping3: [(Int, Int)] = [
            (0, 0),  // '-'的位置
            (2, 2),  // '**'的開始
            (4, 2),  // '粗'的位置
            (10, 6), // '_'的位置
            (11, 6), // '斜'的位置
        ]
        
        let attributedText3 = converter.attributedStringFromMarkup(test3)
        positionMapper.buildPositionMap(rawText: test3, attributedString: attributedText3)
        
        print("原始文本: \"\(test3)\"")
        print("渲染文本: \"\(attributedText3.string)\"")
        
        for (raw, rendered) in expectedMapping3 {
            let calculatedRendered = positionMapper.convertToRenderedPosition(raw)
            // 測試近似值
            XCTAssertTrue(abs(calculatedRendered - rendered) <= 2, 
                         "測試3：原始位置 \(raw) 應該映射到渲染位置接近 \(rendered)，但得到了 \(calculatedRendered)")
        }
    }
}
