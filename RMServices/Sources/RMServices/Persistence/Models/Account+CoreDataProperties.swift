//
//  Account+CoreDataProperties.swift
//  Lemmy-iOS
//
//  Created by Komolbek Ibragimov on 25/12/2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//
//

import Foundation
import CoreData

public extension Account {

    static var fetchRequest: NSFetchRequest<Account> {
        NSFetchRequest<Account>(entityName: String(describing: Account.self))
    }
    
    static var defaultSortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(key: #keyPath(managedLogin), ascending: false)]
    }
    
    @NSManaged var managedLogin: String?
    @NSManaged var managedPassword: String?
    @NSManaged var managedInstance: Instance?
}

public extension Account {
    
    var login: String {
        get { self.managedLogin ?? "No Login" }
        set { self.managedLogin = newValue }
    }
    
    var password: String {
        get { self.managedPassword ?? "No password" }
        set { self.managedPassword = newValue }
    }
    
    var instance: Instance? {
        get { self.managedInstance }
        set { self.managedInstance = newValue }
    }
}
