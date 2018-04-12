//
//  Put.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

/// A `Putter` that executes effects.
///
/// Most commonly used with `Serializable` types.
public typealias Put = Putter<()>

extension Putter /*: Functor*/ {
	/// Applies a function to a value before writing it to a builder.
	public func map<B>(_ f : (A) -> B) -> Putter<B> {
		let pp = self.unPut
		return Putter<B>(unPut: (f(pp.0), pp.1))
	}
}

extension Putter /*: Applicative*/ {
	/// Creates a `Putter` that constructs a value by writing no bytes to a 
	/// builder.
	public static func pure(_ x : A) -> Putter<A> {
		return Putter(unPut: (x, Builder.empty()))
	}

	public func ap<B>(_ m : Putter<(A) -> B>) -> Putter<B> {
		let pp = m.unPut
		let xx = self.unPut
		return Putter<B>(unPut: (pp.0(xx.0), pp.1.append(xx.1)))
	}
}

extension Putter /*: Monad*/ {
	public func flatMap<B>(_ k : (A) -> Putter<B>) -> Putter<B> {
		let pp = self.unPut
		let xx = k(pp.0).unPut
		return Putter<B>(unPut: (xx.0, pp.1.append(xx.1)))
	}
	
	public func then<B>(_ r : Putter<B>) -> Putter<B> {
		return self.flatMap { _ in
			return r
		}
	}
}


//public func putByteString(s : ByteString) -> Put {
//	return Put.tell(Builder.fromByteString(s))
//}
//
//public func putWord16le(x : UInt16) -> Put {
//	return Put.tell(Builder.putWord16le(x))
//}
//
//public func putWord32le(x : UInt32) -> Put {
//	return Put.tell(Builder.putWord32le(x))
//}

/// `Putter` constructs a builder that writes a value to a byte string buffer.
public struct Putter<A> {
	fileprivate let unPut : (A, Builder)

	/// Creates and returns a builder that writes values into a byte string 
	/// buffer.
	func exec() -> Builder {
		return self.unPut.1
	}

	/// Creates and returns abuilder that writes values into a byte string
	/// buffer, then executes the contents of that builder to create a byte 
	/// string.
	public func run() -> ByteString {
		return self.unPut.1.forceByteString
	}

	/// Constructs a `Putter` that yields a mutable buffer suitable for writing
	/// a given number of values.
	public static func byWritingBytes(_ n : Int, _ f : @escaping (UnsafeMutablePointer<UInt8>) -> ()) -> Put {
		return tell(Builder.writeAtMost(n, f: { p in f(p); return n }))
	}

	/// Constructs a `Putter` that writes the bytes contained in a byte string.
	public func putByteString(_ s : ByteString) -> Put {
		return self.flatMap { _ in Put.tell(Builder.fromByteString(s)) }
	}
	
	fileprivate static func tell(_ b : Builder) -> Put {
		return Put(unPut: ((), b))
	}
}
