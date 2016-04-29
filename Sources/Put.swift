//
//  Put.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

public typealias Put = PutM<()>

extension PutM /*: Functor*/ {
	public func map<B>(f : A -> B) -> PutM<B> {
		let pp = self.unPut
		return PutM<B>(unPut: PairS(fst: f(pp.fst), snd: pp.snd))
	}
}

extension PutM /*: Applicative*/ {
	public static func pure(x : A) -> PutM<A> {
		return PutM(unPut: PairS(fst: x, snd: Builder.empty()))
	}

	public func ap<B>(m : PutM<A -> B>) -> PutM<B> {
		let pp = m.unPut
		let xx = self.unPut
		return PutM<B>(unPut: PairS(fst: pp.fst(xx.fst), snd: pp.snd.append(xx.snd)))
	}
}

extension PutM /*: Monad*/ {
	public func flatMap<B>(k : A -> PutM<B>) -> PutM<B> {
		let pp = self.unPut
		let xx = k(pp.fst).unPut
		return PutM<B>(unPut: PairS(fst: xx.fst, snd: pp.snd.append(xx.snd)))
	}
	
	public func then<B>(r : PutM<B>) -> PutM<B> {
		return self >>> r
	}
}

public func >>- <A, B>(m : PutM<A>, fn : A -> PutM<B>) -> PutM<B> {
	return m.flatMap(fn)
}

public func >>> <A, B>(l : PutM<A>, r : PutM<B>) -> PutM<B> {
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

private struct PairS<A> {
	let fst : A
	let snd : Builder
}

public struct PutM<A> {
	private let unPut : PairS<A>
	
	func exec() -> Builder {
		return self.unPut.snd
	}
	
	public func run() -> ByteString {
		return self.unPut.snd.forceByteString
	}
	
	public static func byWritingBytes(n : Int, _ f : UnsafeMutablePointer<UInt8> -> ()) -> Put {
		return tell(Builder.writeAtMost(n, f: { p in f(p); return n }))
	}
	
	public func putByteString(s : ByteString) -> Put {
		return self.flatMap { _ in Put.tell(Builder.fromByteString(s)) }
	}
	
	private static func tell(b : Builder) -> Put {
		return Put(unPut: PairS(fst: (), snd: b))
	}
}
