//
//  Item.swift
//  CV-Commander
//
//  Created by Marvin Heinz on 17.03.24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
