//
//  LinuxMain.swift
//  SwiftCheck
//
//  Created by Robert Widmann on 9/18/16.
//  Copyright © 2016 Typelift. All rights reserved.
//

import XCTest

@testable import AlchemyTests

#if !os(macOS)
XCTMain([
	AlchemySpec.allTests,
])
#endif
