//
//  WeakBox.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 10.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import Foundation

public final class WeakBox<T: AnyObject> {
    public weak var value: T?

    public init(_ value: T) {
        self.value = value
    }
}
