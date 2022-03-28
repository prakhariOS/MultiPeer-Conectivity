//
//  TodoItem.swift
//  Multipeer_demo
//
//  Created by prakhar gupta on 14/03/22.
//

import Foundation


struct TodoItem : Codable
{
    /// A item title
    var title:String
    /// A item is completed ot not.
    var completed:Bool
    /// A item created date.
    var createdAt:Date
    /// A item identifier
    var itemIdentifier:UUID

    ///
    /// A function to save the item.
    ///
    func saveItem()
    {
        DataManager.save(self, with: "\(itemIdentifier.uuidString)")
    }

    ///
    /// A function to delete the item.
    ///
    func deleteItem()
    {
        DataManager.delete(itemIdentifier.uuidString)
    }

    ///
    /// A function mark item as completd.
    ///
    mutating func markAsCompleted()
    {
        self.completed = true
        DataManager.save(self, with: "\(itemIdentifier.uuidString)")
    }

}
