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
	fileprivate let runCont : (ByteString, (ByteString, A) -> DecodeResult<R>) -> DecodeResult<R>

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
	public func map<B>(_ f : @escaping (A) -> B) -> Get<B, R> {
		return Get<B, R> { (i, ks) in
			return self.runCont(i) { (i2, a) in
				return ks(i2, f(a))
			}
		}
	}
}

extension Get /*: Applicative*/ {
	/// Constructs a `Get`ter that reads no bytes and returns a value.
	public static func pure(_ x : A) -> Get<A, R> {
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

extension Get /*: Monoidal*/ {
	public static func zip<B>(_ l : Get<A, R>, _ r : Get<B, R>) -> Get<(A, B), R> {
		return l.flatMap { l in
			return r.flatMap { r in
				return Get<(A, B), R>.pure((l, r))
			}
		}
	}

	public static func zip<B, C>(_ l : Get<A, R>, _ m : Get<B, R>, _ r : Get<C, R>) -> Get<(A, B, C), R> {
		return l.flatMap { l in
			return m.flatMap { m in
				return r.flatMap { r in
					return Get<(A, B, C), R>.pure((l, m, r))
				}
			}
		}
	}

	public static func zip<B, C, D>(_ l : Get<A, R>, _ m1 : Get<B, R>, _ m2 : Get<C, R>, _ r : Get<D, R>) -> Get<(A, B, C, D), R> {
		return l.flatMap { l in
			return m1.flatMap { m1 in
				return m2.flatMap { m2 in
					return r.flatMap { r in
						return Get<(A, B, C, D), R>.pure((l, m1, m2, r))
					}
				}
			}
		}
	}

	public static func zip<B, C, D, E>(_ l : Get<A, R>, _ m1 : Get<B, R>, _ m2 : Get<C, R>, _ m3 : Get<D, R>, _ r : Get<E, R>) -> Get<(A, B, C, D, E), R> {
		return l.flatMap { l in
			return m1.flatMap { m1 in
				return m2.flatMap { m2 in
					return m3.flatMap { m3 in
						return r.flatMap { r in
							return Get<(A, B, C, D, E), R>.pure((l, m1, m2, m3, r))
						}
					}
				}
			}
		}
	}

	public static func zip<B, C, D, E, F>(_ l : Get<A, R>, _ m1 : Get<B, R>, _ m2 : Get<C, R>, _ m3 : Get<D, R>, _ m4 : Get<E, R>, _ r : Get<F, R>) -> Get<(A, B, C, D, E, F), R> {
		return l.flatMap { l in
			return m1.flatMap { m1 in
				return m2.flatMap { m2 in
					return m3.flatMap { m3 in
						return m4.flatMap { m4 in
							return r.flatMap { r in
								return Get<(A, B, C, D, E, F), R>.pure((l, m1, m2, m3, m4, r))
							}
						}
					}
				}
			}
		}
	}

	public static func zip<B, C, D, E, F, G>(_ l : Get<A, R>, _ m1 : Get<B, R>, _ m2 : Get<C, R>, _ m3 : Get<D, R>, _ m4 : Get<E, R>, _ m5 : Get<F, R>, _ r : Get<G, R>) -> Get<(A, B, C, D, E, F, G), R> {
		return l.flatMap { l in
			return m1.flatMap { m1 in
				return m2.flatMap { m2 in
					return m3.flatMap { m3 in
						return m4.flatMap { m4 in
							return m5.flatMap { m5 in
								return r.flatMap { r in
									return Get<(A, B, C, D, E, F, G), R>.pure((l, m1, m2, m3, m4, m5, r))
								}
							}
						}
					}
				}
			}
		}
	}

	public static func zip<B, C, D, E, F, G, H>(_ l : Get<A, R>, _ m1 : Get<B, R>, _ m2 : Get<C, R>, _ m3 : Get<D, R>, _ m4 : Get<E, R>, _ m5 : Get<F, R>, _ m6 : Get<G, R>, _ r : Get<H, R>) -> Get<(A, B, C, D, E, F, G, H), R> {
		return l.flatMap { l in
			return m1.flatMap { m1 in
				return m2.flatMap { m2 in
					return m3.flatMap { m3 in
						return m4.flatMap { m4 in
							return m5.flatMap { m5 in
								return m6.flatMap { m6 in
									return r.flatMap { r in
										return Get<(A, B, C, D, E, F, G, H), R>.pure((l, m1, m2, m3, m4, m5, m6, r))
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

private func ensureN<R>(_ n : Int) -> Get<(), R> {
	func put(_ s : ByteString) -> Get<(), R> {
		return Get { inp, ks in
			return ks(s, ())
		}
	}
	
	func enoughChunks(_ n : Int, _ str : ByteString) -> Either<Int, (ByteString, ByteString)> {
		if str.count >= n {
			return Either.right((str, []))
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

internal indirect enum Either<L, R> {
	case left(L)
	case right(R)
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
