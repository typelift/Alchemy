//
//  Get.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

public typealias ByteString = [UInt8]

indirect enum DecodeResult<A> {
	case Fail(ByteString, String)
	case Done(ByteString, A)
}

internal enum Success<A, R> {
	typealias T = (ByteString, A) -> DecodeResult<R>
}

internal indirect enum Either<L, R> {
	case Left(L)
	case Right(R)
}

internal enum Consume<S> {
	typealias T = (S, ByteString) -> Either<S, (ByteString, ByteString)>
}

public struct Get<A, R> {
	private let runCont : (ByteString, Success<A, R>.T) -> DecodeResult<R>

	public static func byReadingBytes(n : Int, _ f : ByteString -> A) -> Get<A, R> {
		if n == 0 {
			return Get.pure(f([]))
		}
		return ensureN(n).flatMap { _ in
			return Get<A, R> { inp, ks in
				return ks(ByteString(inp[inp.startIndex.advancedBy(n)..<inp.endIndex]), f(inp))
			}
		}
	}
	
	public func byReadingBytes(n : Int, _ f : ByteString -> A) -> Get<A, R> {
		return self.flatMap { _ in Get.byReadingBytes(n, f) }
	}
}

public func runGet<A>(g : Get<A, A>, _ lbs0 : ByteString) -> A  {
	switch g.runCont(lbs0, { i, a in DecodeResult<A>.Done(i, a) }) {
	case let .Done(_, x):
		return x
	case let .Fail(_ , msg):
		fatalError("runGet: " + msg)
	}
}

extension Get /*: Functor*/ {
	func map<B>(f : A -> B) -> Get<B, R> {
		return Get<B, R> { (i, ks) in
			return self.runCont(i) { (i2, a) in
				return ks(i2, f(a))
			}
		}
	}
}

public func <^> <A, B, R>(f : A -> B, g : Get<A, R>) -> Get<B, R> {
	return g.map(f)
}

extension Get /*: Applicative*/ {
	static func pure(x : A) -> Get<A, R> {
		return Get { (s, ks) in
			return ks(s, x)
		}
	}

	public func ap<B>(fn : Get<A -> B, R>) -> Get<B, R> {
		return fn <*> self
	}
}

public func <*> <A, B, R>(d : Get<A -> B, R>, e : Get<A, R>) -> Get<B, R> {
	return d.flatMap { b in
		return e.flatMap { a in
			return Get.pure(b(a))
		}
	}
}

extension Get /*: Monad*/ {
	public func flatMap<B>(f : A -> Get<B, R>) -> Get<B, R> {
		return self >>- f
	}
}

public func >>- <A, B, R>(m : Get<A, R>, fn : A -> Get<B, R>) -> Get<B, R> {
	return Get<B, R> { i, ks in
		return m.runCont(i) { i2, a in
			return fn(a).runCont(i2, ks)
		}
	}
}

func ensureN<R>(n : Int) -> Get<(), R> {
	func put(s : ByteString) -> Get<(), R> {
		return Get { inp, ks in
			return ks(s, ())
		}
	}
	
	func enoughChunks(n : Int, _ str : ByteString) -> Either<Int, (ByteString, ByteString)> {
		if str.count >= n {
			return Either.Right(str, [])
		} else {
			return Either.Left(n - Int(str.count))
		}
	}

	return Get<(), R> { (inp, ks) in
		if inp.count >= n {
			return ks(inp, ())
		} else {
			return Get(runCont: { (inp, ks) in
				switch enoughChunks(n, inp) {
				case let .Left(cnt):
					return Get(runCont: { (_, _) in
						return DecodeResult.Fail(inp, "Not enough bytes.  Expected \(n) bytes but recieved a buffer with only \(cnt) bytes")
					}).runCont([], ks)
				case let .Right((want, rest)):
					return ks(rest, want)
				}
			}).flatMap(put).runCont(inp, ks)
		}
	}
}

//public func getWord16le<R>() -> Get<UInt16, R> {
//	return Get.byReadingBytes(2) { (uu : ByteString) in
//		return UInt16(uu[1]) << 8 
//			| UInt16(uu[0])
//	}
//}
//
//public func getWord32le<R>() -> Get<UInt32, R> {
//	return Get.byReadingBytes(4) { (uu : ByteString) in
//		return UInt32(uu[3]) << 24 as UInt32
//			|  UInt32(uu[2]) << 16 as UInt32
//			|  UInt32(uu[1]) << 8 as UInt32
//			|  UInt32(uu[0])
//	}
//}
