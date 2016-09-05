//
//  FileSpec.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

import Alchemy
import SwiftCheck
import XCTest

extension Foo : Arbitrary {
	static var arbitrary : Gen<Foo> {
		return Gen.compose { c in
			return Foo(
				x: c.generate(), 
				y: c.generate(), 
				z: c.generate(), 
				s: c.generate()
			)
		}
	}
}

struct Foo : Equatable {
	let x : UInt32
	let y : UInt32
	let z : UInt32
	let s : String
	
	static func create(x : UInt32) -> (UInt32) -> (UInt32) -> (String) -> Foo {
		return { y in { z in { s in Foo(x: x, y: y, z: z, s: s) } } }
	}
}

func == (l : Foo, r : Foo) -> Bool {
	return l.x == r.x && l.y == r.y && l.z == r.z
}

extension Foo : Serializable {
	static func deserialize<R>() -> Get<Foo, R> {
		return Foo.create 
			<^> UInt32.deserialize() 
			<*> UInt32.deserialize() 
			<*> UInt32.deserialize()
			<*> String.deserialize()
	}

	var serialize : Put {
		return  self.x.serialize
			>>> self.y.serialize
			>>> self.z.serialize
			>>> self.s.serialize
	}
}


