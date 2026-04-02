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
let CACHEPATH = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
let COVERSPATH = (CACHEPATH as NSString).appendingPathComponent("covers")
let IS_MAC_CATALYST: Bool = {
#if targetEnvironment(macCatalyst)
	return true
#else
	return false
#endif
}()

extension String {
	func localized() -> String {
		return NSLocalizedString(self, comment: "")
	}
}
