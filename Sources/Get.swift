//
//  Get.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

public typealias ByteString = [UInt8]

/// `Get` contains a lazy function that carries the information needed to
/// deserialize a byte string into either value or an error.
public struct Get<A, R> {
	fileprivate let runCont : (ByteString, Success<A, R>.T) -> DecodeResult<R>

	/// Creates a `Get`ter that reads a given number of a bytes from the byte
	/// string buffer to construct a value.
	public static func byReadingBytes(_ n : Int, _ f : @escaping (ByteString) -> A) -> Get<A, R> {
		if n == 0 {
			return Get.pure(f([]))
		}
		return ensureN(n).flatMap { _ in
			return Get<A, R> { inp, ks in
				return ks(ByteString(inp[inp.indices.suffix(from: inp.startIndex.advanced(by: n))]), f(inp))
			}
		}
	}

	/// Extends a `Get`ter to read additional data from a byte string buffer to
	/// construct a value.
	public func byReadingBytes(_ n : Int, _ f : @escaping (ByteString) -> A) -> Get<A, R> {
		return self.flatMap { _ in Get.byReadingBytes(n, f) }
	}
}

/// Executes the function contained in the `Get`ter to deserialize a value.
public func runGet<A>(_ g : Get<A, A>, _ lbs0 : ByteString) -> A  {
	switch g.runCont(lbs0, { i, a in DecodeResult<A>.done(i, a) }) {
	case let .done(_, x):
		return x
	case let .fail(_ , msg):
		fatalError("runGet: " + msg)
	}
}

extension Get /*: Functor*/ {
	/// Applies a function to the result of deserializing a value.
	func map<B>(_ f : @escaping (A) -> B) -> Get<B, R> {
		return Get<B, R> { (i, ks) in
			return self.runCont(i) { (i2, a) in
				return ks(i2, f(a))
			}
		}
	}
}

public func <^> <A, B, R>(f : @escaping (A) -> B, g : Get<A, R>) -> Get<B, R> {
	return g.map(f)
}

extension Get /*: Applicative*/ {
	/// Constructs a `Get`ter that reads no bytes and returns a value.
	static func pure(_ x : A) -> Get<A, R> {
		return Get { (s, ks) in
			return ks(s, x)
		}
	}

	public func ap<B>(_ fn : Get<(A) -> B, R>) -> Get<B, R> {
		return fn.flatMap { b in
			return self.flatMap { a in
				return Get<B, R>.pure(b(a))
			}
		}
	}
}

public func <*> <A, B, R>(d : Get<(A) -> B, R>, e : Get<A, R>) -> Get<B, R> {
	return e.ap(d)
}

extension Get /*: Monad*/ {
	/// Applies a function to continue deserializing values from a buffer.
	public func flatMap<B>(_ fn : @escaping (A) -> Get<B, R>) -> Get<B, R> {
		return Get<B, R> { i, ks in
			return self.runCont(i) { i2, a in
				return fn(a).runCont(i2, ks)
			}
		}
	}
}

public func >>- <A, B, R>(m : Get<A, R>, fn : @escaping (A) -> Get<B, R>) -> Get<B, R> {
	return m.flatMap(fn)
}

private func ensureN<R>(_ n : Int) -> Get<(), R> {
	func put(_ s : ByteString) -> Get<(), R> {
		return Get { inp, ks in
			return ks(s, ())
		}
	}
	
	func enoughChunks(_ n : Int, _ str : ByteString) -> Either<Int, (ByteString, ByteString)> {
		if str.count >= n {
			return Either.right(str, [])
		} else {
			return Either.left(n - Int(str.count))
		}
	}

	return Get<(), R> { (inp, ks) in
		if inp.count >= n {
			return ks(inp, ())
		} else {
			return Get(runCont: { (inp, ks) in
				switch enoughChunks(n, inp) {
				case let .left(cnt):
					return Get(runCont: { (_, _) in
						return DecodeResult.fail(inp, "Not enough bytes.  Expected \(n) bytes but recieved a buffer with only \(cnt) bytes")
					}).runCont([], ks)
				case let .right((want, rest)):
					return ks(rest, want)
				}
			}).flatMap(put).runCont(inp, ks)
		}
	}
}

indirect enum DecodeResult<A> {
	case fail(ByteString, String)
	case done(ByteString, A)
}

internal enum Success<A, R> {
	typealias T = (ByteString, A) -> DecodeResult<R>
}

internal indirect enum Either<L, R> {
	case left(L)
	case right(R)
}

internal enum Consume<S> {
	typealias T = (S, ByteString) -> Either<S, (ByteString, ByteString)>
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
