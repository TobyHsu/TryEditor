import Foundation
import SwiftUI
import Combine

// MARK: - 富文本编辑器UI视图协调器
public class TRichTextEditorCoordinator: NSObject, TRichTextEditorToolbarDelegate {
    internal var editor: TRichTextEditor?
    private var toolbar: TRichTextEditorToolbar?
    public var parent: TRichTextEditorView
    private var cancellables = Set<AnyCancellable>()
    
    init(parent: TRichTextEditorView) {
        self.parent = parent
        super.init()
    }
    
    func setupEditor(_ editor: TRichTextEditor) {
        // 保存编辑器引用
        self.editor = editor
        
        // 确保设置初始内容
        if !parent.text.isEmpty {
            editor.setContent(parent.text)
        }
        
        // 清除之前的订阅
        cancellables.removeAll()
        
        // 监听文本更新 - 修复：将订阅存储到 cancellables 中
        editor.onRawTextUpdate { [weak self] text in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.parent.text != text {
                    self.parent.text = text
                }
            }
        }
        .store(in: &cancellables)
        
        // 监听选择范围变化 - 修复：将订阅存储到 cancellables 中
        editor.onSelectionUpdate { [weak self] range in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.parent.selectedRange = range
            }
        }
        .store(in: &cancellables)
        
        // 设置是否可编辑
        editor.editable = parent.isEditable
    }
    
    func setupToolbar(_ toolbar: TRichTextEditorToolbar) {
        self.toolbar = toolbar
        toolbar.delegate = self
        
        // 连接编辑器和工具栏
        if let editor = editor {
            toolbar.editor = editor
        }
    }
    
    // 应用编辑状态变化
    func updateEditable(_ isEditable: Bool) {
        editor?.editable = isEditable
    }
    
    // 强制刷新
    func refreshContent() {
        editor?.refreshAttributedText()
    }
    
    // 应用样式
    public func didSelectStyle(_ style: MarkupStyle) {
        // 代理方法实现
        // 由工具栏直接调用editor的方法，无需在此处理
    }
}

// MARK: - 富文本编辑器UIViewRepresentable
public struct TRichTextEditorUIView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    var isEditable: Bool
    var toolbarItems: [ToolbarItemType]
    var onRefresh: () -> Void
    
    public init(
        text: Binding<String>,
        selectedRange: Binding<NSRange>,
        isEditable: Bool = true,
        toolbarItems: [ToolbarItemType] = [],
        onRefresh: @escaping () -> Void = {}
    ) {
        self._text = text
        self._selectedRange = selectedRange
        self.isEditable = isEditable
        self.toolbarItems = toolbarItems
        self.onRefresh = onRefresh
    }
    
    public func makeCoordinator() -> TRichTextEditorCoordinator {
        // 直接使用当前实例的绑定属性创建协调器
        let coordinator = TRichTextEditorCoordinator(parent: TRichTextEditorView(
            text: $text,
            selectedRange: $selectedRange,
            isEditable: isEditable
        ))
        return coordinator
    }
    
    public func makeUIView(context: Context) -> UIView {
        // 创建容器视图
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // 创建文本视图
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        
        // 创建工具栏
        let toolbar = TRichTextEditorToolbar(items: toolbarItems)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建编辑器
        let editor = TRichTextEditor(textView: textView)
        
        // 设置协调器
        let coordinator = context.coordinator
        coordinator.setupEditor(editor)
        coordinator.setupToolbar(toolbar)
        
        // 添加视图到容器
        containerView.addSubview(textView)
        containerView.addSubview(toolbar)
        
        // 设置约束
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            toolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            toolbar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            textView.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 为了确保编辑器能够响应外部文本变更，先设置内容
        if !text.isEmpty {
            editor.setContent(text)
        }
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // 获取编辑器
        guard let editor = context.coordinator.editor else { return }
        
        // 检查文本是否需要更新（避免循环更新）
        let currentText = editor.getContent()
        if text != currentText {
            // 内容变更太频繁可能导致性能问题，使用防抖动延迟
            DispatchQueue.main.async {
                editor.setContent(text)
            }
        }
        
        // 更新编辑状态
        if editor.editable != isEditable {
            editor.editable = isEditable
        }
        
        // 检查并刷新内容
        if context.coordinator.parent.shouldRefresh {
            context.coordinator.refreshContent()
            onRefresh()
        }
    }
}

// MARK: - 富文本编辑器SwiftUI视图
public struct TRichTextEditorView: View {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    @State var isEditable: Bool
    @State var shouldRefresh: Bool = false
    
    private var toolbarItems: [ToolbarItemType] = []
    
    public init(
        text: Binding<String>,
        selectedRange: Binding<NSRange> = .constant(NSRange(location: 0, length: 0)),
        isEditable: Bool = true
    ) {
        self._text = text
        self._selectedRange = selectedRange
        self._isEditable = State(initialValue: isEditable)
        
        // 默认工具栏配置
        configureDefaultToolbar()
    }
    
    public var body: some View {
        TRichTextEditorUIView(
            text: $text,
            selectedRange: $selectedRange,
            isEditable: isEditable,
            toolbarItems: toolbarItems,
            onRefresh: {
                shouldRefresh = false
            }
        )
        .onChange(of: isEditable) { newValue in
            // 编辑状态变化时刷新视图
            shouldRefresh = true
        }
    }
    
    // 配置工具栏
    public func toolbar(items: [ToolbarItemType]) -> Self {
        var view = self
        view.toolbarItems = items
        return view
    }
    
    // 设置是否可编辑
    public func editable(_ isEditable: Bool) -> Self {
        var view = self
        view.isEditable = isEditable
        return view
    }
    
    // 强制刷新内容
    public func refresh() -> Self {
        var view = self
        view.shouldRefresh = true
        return view
    }
    
    // 配置默认工具栏
    private mutating func configureDefaultToolbar() {
        // 创建默认系统图标，在实际使用时需要替换为实际的图标资源
        let boldIcon = UIImage(systemName: "bold") ?? UIImage()
        let italicIcon = UIImage(systemName: "italic") ?? UIImage()
        let strikethroughIcon = UIImage(systemName: "strikethrough") ?? UIImage()
        let listBulletIcon = UIImage(systemName: "list.bullet") ?? UIImage()
        let listNumberIcon = UIImage(systemName: "list.number") ?? UIImage()
        let textformatIcon = UIImage(systemName: "textformat.size") ?? UIImage()
        
        // 默认工具栏项目
        toolbarItems = [
            .button(style: MarkupStyle.bold, icon: boldIcon),
            .button(style: MarkupStyle.italic, icon: italicIcon),
            .button(style: MarkupStyle.strikethrough, icon: strikethroughIcon),
            .separator,
            .button(style: MarkupStyle.bulletList(level: 0), icon: listBulletIcon),
            .button(style: MarkupStyle.numberList(level: 0), icon: listNumberIcon),
            .separator,
            .menu(title: "字体", options: [
                ToolbarMenuOption(title: "小", style: MarkupStyle.font(attributes: [StyleAttribute(key: "size", value: "14")])),
                ToolbarMenuOption(title: "中", style: MarkupStyle.font(attributes: [StyleAttribute(key: "size", value: "16")])),
                ToolbarMenuOption(title: "大", style: MarkupStyle.font(attributes: [StyleAttribute(key: "size", value: "20")]))
            ])
        ]
    }
}

// MARK: - 纯显示富文本视图
public struct TRichTextDisplayView: UIViewRepresentable {
    private var text: String
    private var onMentionTap: ((String) -> Void)?
    
    public init(text: String, onMentionTap: ((String) -> Void)? = nil) {
        self.text = text
        self.onMentionTap = onMentionTap
    }
    
    public func makeUIView(context: Context) -> TRichTextView {
        let textView = TRichTextView()
        if let handler = onMentionTap {
            textView.configureMentionTapHandler(handler)
        }
        return textView
    }
    
    public func updateUIView(_ uiView: TRichTextView, context: Context) {
        uiView.setContent(text)
    }
}

// MARK: - 预览示例
struct TRichTextEditorSwiftUIExampleView: View {
    @State private var text = """
    **粗体文本**
    _斜体文本_
    - 项目符号列表项
    - 包含**粗体**的列表项
    1. 数字列表项
    2. 包含_斜体_的数字列表项
    """
    @State private var selectedRange = NSRange(location: 0, length: 0)
    
    var body: some View {
        VStack {
            Text("富文本编辑器")
                .font(.headline)
                .padding()
            
            TRichTextEditorView(text: $text, selectedRange: $selectedRange)
                .padding()
                .frame(height: 300)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            Divider()
            
            Text("只读模式")
                .font(.headline)
                .padding()
            
            TRichTextDisplayView(text: text, onMentionTap: { userId in
                print("点击了用户: \(userId)")
            })
            .padding()
            .frame(height: 200)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
} 
