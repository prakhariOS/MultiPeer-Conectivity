//
//  ItemCell.swift
//  Multipeer_demo
//
//  Created by prakhar gupta on 14/03/22.
//

import UIKit


protocol TodoCellDelegate
{
    func didRequestDelete(_ cell: ItemCell)
    func didRequestShare(_ cell: ItemCell)
}

///
/// A todo item cell.
///
class ItemCell: UITableViewCell
{
    var delegte:TodoCellDelegate?

    /// A todo item tult.
    @IBOutlet var titleLabel: UILabel!
}


// MARK: - Overrides
extension ItemCell
{
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }


    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }
}


// MARK: - Actions
extension ItemCell
{
    ///
    /// A item share action.
    ///
    @IBAction func shareTodoAction(_ sender: UIButton)
    {
        guard  let delegateObject = self.delegte else { return }
        delegateObject.didRequestShare(self)
    }

    ///
    /// A delete item action.
    ///
    @IBAction func deleteTodoAction(_ sender: UIButton)
    {
        guard  let delegateObject = self.delegte else { return }
        delegateObject.didRequestDelete(self)
    }
}
