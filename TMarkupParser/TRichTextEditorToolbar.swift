import Foundation
import UIKit
import Combine

// MARK: - 工具栏项目类型
public enum ToolbarItemType {
    // 按钮类型
    case button(style: MarkupStyle, icon: UIImage)
    
    // 菜单类型
    case menu(title: String, options: [ToolbarMenuOption])
    
    // 分隔线
    case separator
}

// MARK: - 菜单选项
public struct ToolbarMenuOption {
    let title: String
    let style: MarkupStyle
    let icon: UIImage?
    
    public init(title: String, style: MarkupStyle, icon: UIImage? = nil) {
        self.title = title
        self.style = style
        self.icon = icon
    }
}

// MARK: - 工具栏代理
public protocol TRichTextEditorToolbarDelegate: AnyObject {
    func didSelectStyle(_ style: MarkupStyle)
}

// MARK: - 富文本工具栏
public class TRichTextEditorToolbar: UIView {
    // MARK: 属性
    private var items: [ToolbarItemType] = []
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var cancellables = Set<AnyCancellable>()
    
    public weak var delegate: TRichTextEditorToolbarDelegate?
    public weak var editor: TRichTextEditor?
    
    // MARK: - 初始化方法
    public init(frame: CGRect = .zero, items: [ToolbarItemType] = []) {
        self.items = items
        super.init(frame: frame)
        setupViews()
        buildToolbar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - 设置工具栏项目
    public func setItems(_ items: [ToolbarItemType]) {
        self.items = items
        buildToolbar()
    }
    
    // MARK: - 私有辅助方法
    private func setupViews() {
        // 配置滚动视图
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // 配置堆栈视图
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -8)
        ])
        
        // 设置背景色和边框
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
    }
    
    private func buildToolbar() {
        // 清除现有按钮
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 构建工具栏项目
        for item in items {
            let view = createViewForItem(item)
            stackView.addArrangedSubview(view)
        }
        
        // 更新内容大小
        layoutIfNeeded()
        scrollView.contentSize = stackView.bounds.size
    }
    
    private func createViewForItem(_ item: ToolbarItemType) -> UIView {
        switch item {
        case .button(let style, let icon):
            return createButtonItem(style: style, icon: icon)
            
        case .menu(let title, let options):
            return createMenuItem(title: title, options: options)
            
        case .separator:
            return createSeparator()
        }
    }
    
    private func createButtonItem(style: MarkupStyle, icon: UIImage) -> UIView {
        let button = UIButton(type: .system)
        button.setImage(icon, for: .normal)
        button.tintColor = .systemBlue
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // 设置圆角
        button.layer.cornerRadius = 6
        
        // 添加点击事件
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        // 存储样式信息
        button.tag = items.count // 使用tag作为标识
        objc_setAssociatedObject(button, &AssociatedKeys.styleKey, style, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return button
    }
    
    private func createMenuItem(title: String, options: [ToolbarMenuOption]) -> UIView {
        let menuButton = UIButton(type: .system)
        menuButton.setTitle(title, for: .normal)
        menuButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        menuButton.tintColor = .systemBlue
        menuButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        menuButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // 设置圆角和边框
        menuButton.layer.cornerRadius = 6
        menuButton.layer.borderWidth = 0.5
        menuButton.layer.borderColor = UIColor.systemGray4.cgColor
        
        // 创建菜单
        if #available(iOS 14.0, *) {
            var menuActions = [UIMenuElement]()
            
            for option in options {
                let action = UIAction(title: option.title, image: option.icon) { [weak self] _ in
                    self?.styleSelected(option.style)
                }
                menuActions.append(action)
            }
            
            menuButton.menu = UIMenu(children: menuActions)
            menuButton.showsMenuAsPrimaryAction = true
        } else {
            // iOS 13 兼容
            menuButton.addTarget(self, action: #selector(showOptionsAlert(_:)), for: .touchUpInside)
            objc_setAssociatedObject(menuButton, &AssociatedKeys.optionsKey, options, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return menuButton
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return separator
    }
    
    // MARK: - 事件处理
    @objc private func buttonTapped(_ sender: UIButton) {
        if let style = objc_getAssociatedObject(sender, &AssociatedKeys.styleKey) as? MarkupStyle {
            styleSelected(style)
        }
    }
    
    @objc private func showOptionsAlert(_ sender: UIButton) {
        guard let options = objc_getAssociatedObject(sender, &AssociatedKeys.optionsKey) as? [ToolbarMenuOption] else {
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for option in options {
            alertController.addAction(UIAlertAction(title: option.title, style: .default) { [weak self] _ in
                self?.styleSelected(option.style)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        // 获取顶层视图控制器并显示警告
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            var topVC = topController
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            topVC.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func styleSelected(_ style: MarkupStyle) {
        // 通知代理
        delegate?.didSelectStyle(style)
        
        // 直接应用到编辑器
        if let editor = editor {
            // 处理不同类型的样式
            if style.style is BulletListStyle || style.style is NumberListStyle {
                // 列表样式应用
                editor.applyListStyle(style)
            } else if style.name == "删除线" || style.name == "strikethrough" {
                // 使用特殊处理，确保删除线正确应用
                editor.applyStyle(style, mode: .toggleExisting)
            } else if style.name == "代码" || style.name == "code" {
                // 行内代码
                editor.applyStyle(style, mode: .toggleExisting)
            } else if style.name == "链接" || style.name == "link" {
                // 链接的处理可能需要额外输入
                editor.applyStyle(style, mode: .toggleExisting)
            } else {
                // 其他普通样式处理
                editor.applyStyle(style, mode: .toggleExisting)
            }
            
            // 每次样式应用后，确保编辑器控件获得焦点
            editor.becomeFirstResponder()
        }
    }
}

// MARK: - 私有辅助类型
private struct AssociatedKeys {
    static var styleKey = "styleKey"
    static var optionsKey = "optionsKey"
} 