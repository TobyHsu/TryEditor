# TMarkupParser

TMarkupParser 是一個用於解析和轉換富文本標記的 Swift 框架。它支援類 Markdown 語法和自定義標記，可以在純文本和富文本之間進行轉換。

## 功能特點

- 支援基礎 Markdown 語法（粗體、斜體、刪除線等）
- 支援多級列表（有序和無序）
- 支援自定義樣式標記
- 提供富文本和標記文本的雙向轉換
- 支援樣式巢狀和屬性自定義

## 安裝

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/TMarkupParser.git", from: "1.0.0")
]
```

## 快速開始

### 基本用法

```swift
// 建立解析器和轉換器
let parser = MarkupParser()
let converter = MarkupConverter(parser: parser)

// 解析帶樣式的文本
let text = """
**標題**
- 列表項1
  - 子列表項
- _斜體列表項_
"""

// 轉換為富文本
let attributedString = converter.attributedStringFromMarkup(text)

// 轉換回標記文本
let markupText = converter.markupFromAttributedString(attributedString)
```

## 詳細文檔

### 支援的標記語法

1. **基礎樣式**
   ```
   **粗體文本**
   _斜體文本_
   ~~刪除線文本~~
   `行內程式碼`
   ```

2. **列表**
   ```
   - 無序列表項
     - 縮排的子項
   1. 有序列表項
   2. 第二個項目
   ```

3. **自定義樣式**
   ```
   {{font color="#FF0000" size="20"}}
   紅色大字體文本
   {{/font}}
   ```

### 核心組件

#### 1. MarkupParser（標記解析器）

```swift
// 建立解析器實例
let parser = MarkupParser()

// 解析文本
let node = parser.parse(rawText)
```

#### 2. MarkupNode（標記節點）

```swift
// 文本節點
let textNode = TextNode(text: "普通文本")

// 樣式節點
let styleNode = StyleNode(style: MarkupStyle.bold, children: [textNode])

// 根節點
let rootNode = RootNode(children: [styleNode])
```

#### 3. MarkupVisitor（訪問器）

```swift
public protocol MarkupVisitor {
    associatedtype Result
    
    func visit(text: TextNode) -> Result
    func visit(style: StyleNode) -> Result
    func visit(root: RootNode) -> Result
}
```

#### 4. MarkupConverter（轉換器）

```swift
let converter = MarkupConverter(
    parser: parser,
    baseFont: .systemFont(ofSize: 16),
    defaultTextColor: .label,
    defaultBackgroundColor: .clear
)
```

### 進階用法

#### 自定義字體和顏色

```swift
let text = """
{{font color="#FF0000" size="20"}}
紅色大字體文本
{{/font}}
"""
```

#### 多級列表處理

```swift
let text = """
- 一級列表
  - 二級列表1
  - 二級列表2
    - 三級列表
- 另一個一級列表
"""
```

## 注意事項

1. **格式規範**
   - 列表標記（`-` 或數字）後必須有一個空格
   - 子列表必須有正確的縮排（兩個空格或一個 tab）
   - 樣式標籤必須正確閉合

2. **效能考慮**
   - 對於大型文本，建議分段處理
   - 避免過深的巢狀層級

3. **錯誤處理**
   - 解析器會盡可能處理不規範的輸入
   - 未閉合的標籤可能導致解析結果不符合預期
   - 建議在使用前驗證輸入文本的格式

## 擴展功能

框架支援以下擴展：
- 註冊新的樣式模式
- 實現自定義訪問器
- 新增新的節點類型

## 貢獻

歡迎提交 Pull Request 或建立 Issue。

## 授權條款

MIT License

## 作者

[Your Name]

## 聯絡方式

- Email: [your.email@example.com]
- GitHub: [@yourusername] 