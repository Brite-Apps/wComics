//
//  Common.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import Foundation
import UIKit

let DOCPATH = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

extension String {
	func localized() -> String {
		return NSLocalizedString(self, comment: "")
	}
}
