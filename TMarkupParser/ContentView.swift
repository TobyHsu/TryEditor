//
//  ContentView.swift
//  TMarkupParser
//
//  Created by Hsu Toby on 2025/3/9.
//

import SwiftUI

struct ContentView: View {
    @State private var text = """
    # TMarkupParser 富文本编辑器示例
    
    **粗体文本** 和 _斜体文本_ 示例
    
    ## 列表示例
    - 项目符号列表项1
    - 包含**粗体**的列表项
    - _斜体样式_的列表项
    
    ## 数字列表示例
    1. 数字列表项1
    2. 包含{{font color="#FF0000"}}红色文字{{/font}}的数字列表项
    3. 包含[链接](https://apple.com)的列表项
    
    > 这是一段引用文本
    > 支持多行显示
    
    `这是行内代码`
    
    ```
    // 这是代码块
    func example() {
        print("Hello, World!")
    }
    ```
    
    ***
    
    最后一行文本
    """
    
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var isEditable = true
    
    var body: some View {
        VStack {
            Text("TMarkupParser 富文本编辑器")
                .font(.largeTitle)
                .padding()
            
            HStack {
                Toggle("可编辑模式", isOn: $isEditable)
                    .padding(.horizontal)
                
                Button(action: {
                    // 导出内容
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = text
                }) {
                    Label("复制内容", systemImage: "doc.on.doc")
                }
                .padding(.horizontal)
                
                // 添加测试按钮
                Button(action: {
                    // 测试文本更新
                    text += "\n\n**测试追加内容 - \(Date().formatted(date: .abbreviated, time: .standard))**"
                }) {
                    Label("测试更新", systemImage: "arrow.counterclockwise")
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            TRichTextEditorView(text: $text, selectedRange: $selectedRange, isEditable: isEditable)
                .padding()
                .frame(maxHeight: .infinity)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            
            if !isEditable {
                Text("当前为只读模式，编辑器将作为TRichTextView使用")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("当前选择范围：\(selectedRange.location), \(selectedRange.length)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("字符数: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    ContentView()
}
