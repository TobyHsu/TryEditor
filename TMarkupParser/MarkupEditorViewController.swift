import UIKit

class MarkupEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var markupEditor: MarkupEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMarkupEditor()
        setupTestButtons()
    }
    
    func setupMarkupEditor() {
        markupEditor = MarkupEditor()
        markupEditor.textView.font = UIFont.systemFont(ofSize: 16)
        markupEditor.textView.textColor = .black
        
        view.addSubview(markupEditor.textView)
        markupEditor.textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            markupEditor.textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            markupEditor.textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            markupEditor.textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            markupEditor.textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
        
        // 设置一些初始文本
        markupEditor.textView.text = "请在此输入文本。你可以使用底部按钮插入各种元素。"
    }
    
    func setupTestButtons() {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        
        let tableButton = UIButton(type: .system)
        tableButton.setTitle("插入表格", for: .normal)
        tableButton.addTarget(self, action: #selector(insertTableTapped), for: .touchUpInside)
        
        let mentionButton = UIButton(type: .system)
        mentionButton.setTitle("插入提及", for: .normal)
        mentionButton.addTarget(self, action: #selector(insertMentionTapped), for: .touchUpInside)
        
        let imageButton = UIButton(type: .system)
        imageButton.setTitle("插入图片", for: .normal)
        imageButton.addTarget(self, action: #selector(insertImageTapped), for: .touchUpInside)
        
        let gifButton = UIButton(type: .system)
        gifButton.setTitle("插入GIF", for: .normal)
        gifButton.addTarget(self, action: #selector(insertGIFTapped), for: .touchUpInside)
        
        buttonStackView.addArrangedSubview(tableButton)
        buttonStackView.addArrangedSubview(mentionButton)
        buttonStackView.addArrangedSubview(imageButton)
        buttonStackView.addArrangedSubview(gifButton)
        
        view.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            buttonStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func insertTableTapped() {
        // 创建表格数据
        let tableData = [
            ["姓名", "年龄", "职业"],
            ["张三", "28", "工程师"],
            ["李四", "35", "设计师"],
            ["王五", "42", "产品经理"]
        ]
        
        let markupEditor = self.markupEditor
        if let selectedRange = markupEditor.textView.selectedRange {
            markupEditor.insertTable(data: tableData, at: selectedRange)
        }
    }
    
    @objc func insertMentionTapped() {
        let userId = "user123"
        let displayName = "@张三"
        
        let markupEditor = self.markupEditor
        if let selectedRange = markupEditor.textView.selectedRange {
            markupEditor.insertMention(userId: userId, displayName: displayName, at: selectedRange) { userId in
                let alert = UIAlertController(title: "点击了用户", message: "用户ID: \(userId)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    @objc func insertImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    @objc private func insertGIFTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.gif])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage, 
           let imageData = image.jpegData(compressionQuality: 0.8) {
            if let selectedRange = markupEditor.textView.selectedRange {
                markupEditor.insertLocalImage(data: imageData, at: selectedRange)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // 确保 URL 是 GIF 文件
        if url.pathExtension.lowercased() == "gif" {
            insertGIF(url: url)
        }
    }
} 