//
//  BoardModel.swift
//  DragAndDrop
//
//  Created by Khurram Shahzad on 17/03/2021.
//

import Foundation

class BoardModel: Codable {
    
    var title: String
    var items: [String]
    
    init(title: String, items: [String]) {
        self.title = title
        self.items = items
    }
}
