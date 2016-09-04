//
//  Put.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

public typealias Put = Putter<()>

extension Putter /*: Functor*/ {
	public func map<B>(_ f : (A) -> B) -> Putter<B> {
		let pp = self.unPut
		return Putter<B>(unPut: (f(pp.0), pp.1))
	}
}

extension Putter /*: Applicative*/ {
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
		return self >>> r
	}
}

public func >>- <A, B>(m : Putter<A>, fn : (A) -> Putter<B>) -> Putter<B> {
	return m.flatMap(fn)
}

public func >>> <A, B>(l : Putter<A>, r : Putter<B>) -> Putter<B> {
	return l.flatMap { _ in
		return r
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

public struct Putter<A> {
	fileprivate let unPut : (A, Builder)
	
	func exec() -> Builder {
		return self.unPut.1
	}
	
	public func run() -> ByteString {
		return self.unPut.1.forceByteString
	}
	
	public static func byWritingBytes(_ n : Int, _ f : @escaping (UnsafeMutablePointer<UInt8>) -> ()) -> Put {
		return tell(Builder.writeAtMost(n, f: { p in f(p); return n }))
	}
	
	public func putByteString(_ s : ByteString) -> Put {
		return self.flatMap { _ in Put.tell(Builder.fromByteString(s)) }
	}
	
	fileprivate static func tell(_ b : Builder) -> Put {
		return Put(unPut: ((), b))
	}
}
