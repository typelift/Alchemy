//
//  AlchemySpec.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

import Alchemy
import SwiftCheck
import XCTest

func roundTripWith<A : protocol<Equatable, Serializable>>(x : A) -> Property {
	return x ==== runGet(A.deserialize(), x.serialize.run())
}

class AlchemySpec : XCTestCase {
	func testProperties() {
		property("round trip") <- forAll { (x : Int8) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : Int16) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : Int16) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : Int32) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : Int64) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : Int) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : UInt8) in
			return roundTripWith(x)
		}

		property("round trip") <- forAll { (x : UInt16) in
			return roundTripWith(x)
		}

		property("round trip") <- forAll { (x : UInt16) in
			return roundTripWith(x)
		}

		property("round trip") <- forAll { (x : UInt32) in
			return roundTripWith(x)
		}

		property("round trip") <- forAll { (x : UInt64) in
			return roundTripWith(x)
		}
		
		property("round trip") <- forAll { (x : UInt) in
			return roundTripWith(x)
		}
		
//		let arg = CheckerArguments(replay: (StdGen(11130740, 1029952160), 0))
//		property("round trip", arguments: arg) <- forAll { (x : String) in
//			return x ==== runGet(String.deserialize(), x.serialize.run())
//		}
		
		property("round trip") <- forAll { (x : Foo) in
			return roundTripWith(x)
		}
	}
}
