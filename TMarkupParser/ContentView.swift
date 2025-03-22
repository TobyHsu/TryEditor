//
//  ContentView.swift
//  TMarkupParser
//
//  Created by Hsu Toby on 2025/3/9.
//

import SwiftUI

struct ContentView: View {
    let parser = MarkupParser()
    let rawText = """
    * 第一項
    * 第二項
    * 子項目
    * 第三項
    12345\tGGGGG
    
    """
    @State var attributedString = NSAttributedString("")
    @State var parseRawText = ""

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            TTTextView(a: $attributedString)
//            Text(AttributedString(attributedString))
            Divider()
            Text(parseRawText)
        }
        .padding()
        .task {
//            let converter = MarkupConverter(parser: parser, baseFont: UIFont.systemFont(ofSize: 16))
//            attributedString = converter.attributedStringFromMarkup(rawText)
//            print(attributedString)
//            parseRawText = converter.markupFromAttributedString(attributedString)
//            let node = parser.parse(rawText)
//            let visitor = AttributedStringVisitor()
//            attributedString = node.accept(visitor)
//            parseRawText = converter.markupFromAttributedString(attributedString)
        }
    }
}

struct TTTextView: UIViewRepresentable {
    @Binding var a: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isSelectable = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = a
    }
}


#Preview {
    ContentView()
}
