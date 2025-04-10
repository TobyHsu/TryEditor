import UIKit

class MarkupEditorViewController: UIViewController {
    private var markupEditor: MarkupEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupMarkupEditor()
        setupTestButtons()
    }
    
    private func setupMarkupEditor() {
        // 設置導航欄
        title = "Markup Editor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "預覽",
            style: .plain,
            target: self,
            action: #selector(previewTapped)
        )
        
        // 設置編輯器
        let editorFrame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: view.bounds.height
        )
        markupEditor = MarkupEditor(frame: editorFrame)
        
        // 添加到視圖
        let textView = markupEditor.getTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        // 設置約束
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 設置初始文本
        textView.text = """
        歡迎使用 Markup Editor！

        你可以：
        1. 使用工具欄添加樣式
        2. 直接輸入 Markdown 語法
        3. 預覽最終效果

        支持的樣式：
        - **粗體**
        - _斜體_
        - 列表
        > 引用
        """
    }
    
    private func setupTestButtons() {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 10
        buttonStackView.distribution = .fillEqually
        
        // 创建按钮
        let insertTableButton = UIButton(type: .system)
        insertTableButton.setTitle("插入表格", for: .normal)
        insertTableButton.addTarget(self, action: #selector(insertTableTapped), for: .touchUpInside)
        
        let insertMentionButton = UIButton(type: .system)
        insertMentionButton.setTitle("插入提及", for: .normal)
        insertMentionButton.addTarget(self, action: #selector(insertMentionTapped), for: .touchUpInside)
        
        let insertImageButton = UIButton(type: .system)
        insertImageButton.setTitle("插入图片", for: .normal)
        insertImageButton.addTarget(self, action: #selector(insertImageTapped), for: .touchUpInside)
        
        // 添加按钮到堆栈视图
        buttonStackView.addArrangedSubview(insertTableButton)
        buttonStackView.addArrangedSubview(insertMentionButton)
        buttonStackView.addArrangedSubview(insertImageButton)
        
        // 添加堆栈视图到主视图
        view.addSubview(buttonStackView)
        
        // 设置布局约束
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func insertTableTapped() {
        // 示例表格数据
        let tableData = [
            ["姓名", "年龄", "职业"],
            ["张三", "30", "工程师"],
            ["李四", "25", "设计师"],
            ["王五", "35", "产品经理"]
        ]
        
        // 在当前位置插入表格
        if let selectedRange = markupEditor.getTextView().selectedRange {
            markupEditor.insertTable(data: tableData, at: selectedRange)
        }
    }
    
    @objc private func insertMentionTapped() {
        // 在当前位置插入@提及
        if let selectedRange = markupEditor.getTextView().selectedRange {
            markupEditor.insertMention(userId: "user123", displayName: "@张三", at: selectedRange) { userId in
                // 点击提及时的回调
                let alert = UIAlertController(title: "提及点击", message: "用户ID: \(userId)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    @objc private func insertImageTapped() {
        // 打开图片选择器
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @objc private func previewTapped() {
        let previewVC = MarkupPreviewViewController(
            content: markupEditor.getTextView().text
        )
        navigationController?.pushViewController(previewVC, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MarkupEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        // 获取选择的图片
        if let image = info[.originalImage] as? UIImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            // 在当前位置插入图片
            if let selectedRange = markupEditor.getTextView().selectedRange {
                markupEditor.insertLocalImage(data: imageData, at: selectedRange)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension MarkupEditorViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let gifURL = urls.first else { return }
        
        let textView = markupEditor.getTextView()
        markupEditor.insertGIF(url: gifURL, at: textView.selectedRange)
    }
} 