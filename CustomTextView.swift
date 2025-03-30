import UIKit

class CustomTextView: UITextView {
    private var nonSelectableRanges: [NSRange] = []
    
    override func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        if let pos = super.position(from: position, offset: offset) {
            let location = offset(from: beginningOfDocument, to: pos)
            
            for range in nonSelectableRanges {
                if NSLocationInRange(location, range) {
                    if offset > 0 {
                        return super.position(from: position, offset: range.length)
                    } else {
                        return super.position(from: position, offset: -range.length)
                    }
                }
            }
            return pos
        }
        return nil
    }
    
    func addNonSelectableRange(_ range: NSRange) {
        nonSelectableRanges.append(range)
    }
    
    func clearNonSelectableRanges() {
        nonSelectableRanges.removeAll()
    }
} 