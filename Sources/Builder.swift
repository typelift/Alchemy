//
//  Builder.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

struct Buffer {
	let buf : UnsafeMutablePointer<UInt8>
	let offset : Int
	let used : Int
	let left : Int

	init(buf : UnsafeMutablePointer<UInt8>, offset : Int, used : Int, left : Int) {
		self.buf = buf
		self.offset = offset
		self.used = used
		self.left = left
	}

	init(size : Int) {
		self.buf = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
		self.offset = 0
		self.used = 0
		self.left = size
	}

	func writeBuffer(_ f : (UnsafeMutablePointer<UInt8>) -> Int) -> Buffer {
		let n = f(self.buf.advanced(by: self.offset + self.used))
		return Buffer(buf: self.buf, offset: self.offset, used: (self.used + n), left: self.left - n)
	}
	
	fileprivate static let defaultSize = 32 * (1024) - (2 * MemoryLayout<Int>.size)
}

struct Builder {
	let runBuilder : (((Buffer) -> ByteString), Buffer) -> ByteString

	var forceByteString : ByteString {
		let buf = Buffer(size: Buffer.defaultSize)
		let s = self.append(Builder.flush()).runBuilder({ _ in [] }, buf)
		buf.buf.deallocate(capacity: buf.used + buf.left)
		return s
	}

	static func empty() -> Builder {
		return Builder { k, buf in k(buf) }
	}

	static func mapBuilder(_ f : @escaping (ByteString) -> ByteString) -> Builder {
		return Builder { k, b in return f(k(b)) }
	}

	static func fromByteString(_ bs : ByteString) -> Builder {
		if bs.isEmpty {
			return empty()
		} else {
			return flush().append(Builder.mapBuilder({ ss in bs + ss }))
		}
	}

	static func withSize(_ f : @escaping (Int) -> Builder) -> Builder {
		return Builder { k, buf in f(buf.left).runBuilder(k, buf) }
	}

	static func withBuffer(_ f : @escaping (Buffer) -> Buffer) -> Builder {
		return Builder { k, buf in k(f(buf)) }
	}

	static func ensureFree(_ n : Int) -> Builder {
		return withSize { l in
			if n <= l {
				return empty()
			} else {
				return flush().append(withBuffer({ _ in Buffer(size: max(n, Buffer.defaultSize)) }))
			}
		}
	}

	static func writeAtMost(_ n : Int, f : @escaping (UnsafeMutablePointer<UInt8>) -> Int) -> Builder {
		return ensureFree(n).append(withBuffer({ b in b.writeBuffer(f) }))
	}

	static func flush() -> Builder {
		return Builder { k, buf in
			if buf.used == 0 {
				return k(buf)
			} else {
				let b = Buffer(buf: buf.buf, offset: buf.offset + buf.used, used: 0, left: buf.left)
				let bs = ByteString(UnsafeBufferPointer(start: buf.buf, count: buf.used))
				return bs + k(b)
			}
		}
	}

//	static func putWord16le(w : UInt16) -> Builder {
//		return writeN(2) { buf in
//			buf[0] = UInt8(truncatingBitPattern: w)
//			buf[1] = UInt8(truncatingBitPattern: w >> 8)
//		}
//	}
//
//	static func putWord32le(w : UInt32) -> Builder {
//		return writeN(4) { buf in
//			buf[0] = UInt8(truncatingBitPattern: w)
//			buf[1] = UInt8(truncatingBitPattern: w >> 8)
//			buf[2] = UInt8(truncatingBitPattern: w >> 16)
//			buf[3] = UInt8(truncatingBitPattern: w >> 24)
//		}
//	}
//	
//	static func putWord64le(w : UInt64) -> Builder {
//		return writeN(8) { buf in
//			buf[0] = UInt8(truncatingBitPattern: w)
//			buf[1] = UInt8(truncatingBitPattern: w >> 8)
//			buf[2] = UInt8(truncatingBitPattern: w >> 16)
//			buf[3] = UInt8(truncatingBitPattern: w >> 24)
//			buf[4] = UInt8(truncatingBitPattern: w >> 32)
//			buf[5] = UInt8(truncatingBitPattern: w >> 40)
//			buf[6] = UInt8(truncatingBitPattern: w >> 48)
//			buf[7] = UInt8(truncatingBitPattern: w >> 56)
//		}
//	}

	func append(_ other : Builder) -> Builder {
		return Builder { k, buf in self.runBuilder({ (buf2) in other.runBuilder(k, buf2) }, buf) }
	}
}

