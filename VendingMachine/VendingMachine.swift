//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Paul Jackson on 7/3/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//

import Foundation
import UIKit

// Protocols
protocol ItemType {
    var price: Double { get }
    var quantity: Double { get set }
}

protocol VendingMachineType {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: ItemType] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: ItemType])
    
    func vend(selection: VendingSelection, quantity: Double) throws
    func itemForCurrentSelection(selection: VendingSelection) -> ItemType?
    func deposit(amount: Double)
}


// Error Types

enum InventoryError: ErrorType {
    case InvalidResourceError
    case ConversionError
    case InvalidKey
}

enum VendingMachineError: ErrorType {
    case InvalidSelction
    case OutOfStock
    case InsufficientFunds(required: Double)
}

// Concreate Types

enum VendingSelection: String {
    case Soda
    case DietSoda
    case Chips
    case Cookie
    case Sandwich
    case Wrap
    case CandyBar
    case PopTart
    case Water
    case FruitJuice
    case SportsDrink
    case Gum
    
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
            return image
        } else {
            return UIImage(named: "Default")!
        }
    }
}

struct VendingItem: ItemType {
    let price: Double
    var quantity: Double
}

class VendingMachine: VendingMachineType {
    let selection: [VendingSelection] = [.Soda,
                                         .DietSoda,
                                         .Chips,
                                         .Cookie,
                                         .Sandwich,
                                         .Wrap,
                                         .CandyBar,
                                         .PopTart,
                                         .Water,
                                         .FruitJuice,
                                         .SportsDrink,
                                         .Gum]
    
    var inventory: [VendingSelection : ItemType]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : ItemType]) {
        self.inventory = inventory
    }
    
    func vend(selection: VendingSelection, quantity: Double) throws {
        guard var item = inventory[selection] else {
            throw VendingMachineError.InvalidSelction
        }
        
        guard item.quantity > 0 else {
            throw VendingMachineError.OutOfStock
        }
        
        item.quantity -= quantity
        inventory.updateValue(item, forKey: selection)
        
        let totalPrice = item.price * quantity
        
        if amountDeposited >= totalPrice {
            amountDeposited -= totalPrice
        } else {
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.InsufficientFunds(required: amountRequired)
        }
    }
    
    func itemForCurrentSelection(selection: VendingSelection) -> ItemType? {
        return inventory[selection]
    }
    
    func deposit(amount: Double) {
        amountDeposited += amount
    }
}

// Helper Classes

class PlistConverter {
    class func dictonaryFromfile(resource: String, ofType type: String) throws -> [String :  AnyObject] {
        guard let path = NSBundle.mainBundle().pathForResource(resource, ofType: type) else {
           throw InventoryError.InvalidResourceError
        }
        
        guard let dictionary = NSDictionary(contentsOfFile: path),
            let castDictionary = dictionary as? [String: AnyObject] else {
                throw InventoryError.ConversionError
        }
        
        return castDictionary
    }
}

class InventoryUnarchiver {
    class func vendingInventoryFromDictionary(dictionary: [String: AnyObject]) throws -> [VendingSelection: ItemType] {
        var inventory: [VendingSelection : ItemType] = [:]
        
        for(key, value) in dictionary {
            if let itemDictionary = value as? [String : Double],
            let price = itemDictionary["price"], let quantity = itemDictionary["quantity"] {
                let item = VendingItem(price: price, quantity: quantity)
                
                guard let key = VendingSelection(rawValue: key) else {
                    throw InventoryError.InvalidKey
                }
                
                inventory.updateValue(item, forKey: key)

            }
        }
        return inventory
    }
}