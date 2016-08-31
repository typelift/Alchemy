//
//  Serialize.swift
//  Alchemy
//
//  Created by Robert Widmann on 10/23/15.
//  Copyright © 2016 TypeLift. All rights reserved.
//

public protocol Serializable {
	static func deserialize<R>() -> Get<Self, R>
	var serialize : Put { get }
}

extension Bool : Serializable {
	public static func deserialize<R>() -> Get<Bool, R> {
		return UInt8.deserialize().map { i in
			if i == 0 {
				return false
			} else if i == 1 {
				return true
			} else {
				fatalError("Could not decode Bool")
			}
		}
	}

	public var serialize : Put {
		return ((self ? 1 : 0) as UInt8).serialize
	}
}

extension Int8 : Serializable {
	public static func deserialize<R>() -> Get<Int8, R> {
		return Get.byReadingBytes(1) { uu in Int8(bitPattern: uu[0]) }
	}
	
	public var serialize : Put {
		return UInt8(bitPattern: self).serialize
	}
}

extension Int16 : Serializable {
	public static func deserialize<R>() -> Get<Int16, R> {
		return Get.byReadingBytes(2) { (uu : ByteString) in
			return Int16(uu[0]) << 8
				|  Int16(uu[1])
		}
	}
	
	public var serialize : Put {
		return UInt16(bitPattern: self).serialize
	}
}

extension Int32 : Serializable {
	public static func deserialize<R>() -> Get<Int32, R> {
		return Get.byReadingBytes(4) { (uu : ByteString) in
			return (Int32(uu[0]) << 24) as Int32
				|  (Int32(uu[1]) << 16) as Int32
				|  (Int32(uu[2]) << 8) as Int32
				|  Int32(uu[3])
		}
	}
	
	public var serialize : Put {
		return UInt32(bitPattern: self).serialize
	}
}

extension Int64 : Serializable {
	public static func deserialize<R>() -> Get<Int64, R> {
		return Get.byReadingBytes(8) { (uu : ByteString) in
			return (Int64(uu[0]) << 56) as Int64
				|  (Int64(uu[1]) << 48) as Int64
				|  (Int64(uu[2]) << 40) as Int64
				|  (Int64(uu[3]) << 32) as Int64
				|  (Int64(uu[4]) << 24) as Int64
				|  (Int64(uu[5]) << 16) as Int64
				|  (Int64(uu[6]) << 8) as Int64
				|  Int64(uu[7])
		}
	}
	
	public var serialize : Put {
		return UInt64(bitPattern: self).serialize
	}
}

extension Int : Serializable {
	public static func deserialize<R>() -> Get<Int, R> {
	#if (arch(x86_64) || arch(arm64))
		return Int64.deserialize().map { Int($0) }
	#else
		return Int32.deserialize().map { Int($0) }
	#endif
	}
	
	public var serialize : Put {
	#if (arch(x86_64) || arch(arm64))
		return Int64(self).serialize
	#else
		return Int32(self).serialize
	#endif
	}
}

extension UInt8 : Serializable {
	public static func deserialize<R>() -> Get<UInt8, R> {
		return Get.byReadingBytes(1) { uu in uu[0] }
	}

	public var serialize : Put {
		return Put.byWritingBytes(1) { buf in
			buf.pointee = self
		}
	}
}

extension UInt16 : Serializable {
	public static func deserialize<R>() -> Get<UInt16, R> {
		return Get.byReadingBytes(2) { (uu : ByteString) in
			return UInt16(uu[0]) << 8
				|  UInt16(uu[1])
		}
	}

	public var serialize : Put {
		return Put.byWritingBytes(2) { buf in
			buf[0] = UInt8(truncatingBitPattern: self >> 8)
			buf[1] = UInt8(truncatingBitPattern: self)
		}
	}
}

extension UInt32 : Serializable {
	public static func deserialize<R>() -> Get<UInt32, R> {
		return Get.byReadingBytes(4) { (uu : ByteString) in
			return (UInt32(uu[0]) << 24) as UInt32
				|  (UInt32(uu[1]) << 16) as UInt32
				|  (UInt32(uu[2]) << 8) as UInt32
				|  UInt32(uu[3])
		}
	}

	public var serialize : Put {
		return Put.byWritingBytes(4) { buf in
			buf[0] = UInt8(truncatingBitPattern: self >> 24)
			buf[1] = UInt8(truncatingBitPattern: self >> 16)
			buf[2] = UInt8(truncatingBitPattern: self >> 8)
			buf[3] = UInt8(truncatingBitPattern: self)
		}
	}
}

extension UInt64 : Serializable {
	public static func deserialize<R>() -> Get<UInt64, R> {
		return Get.byReadingBytes(8) { (uu : ByteString) in
			return (UInt64(uu[0]) << 56) as UInt64
				|  (UInt64(uu[1]) << 48) as UInt64
				|  (UInt64(uu[2]) << 40) as UInt64
				|  (UInt64(uu[3]) << 32) as UInt64
				|  (UInt64(uu[4]) << 24) as UInt64
				|  (UInt64(uu[5]) << 16) as UInt64
				|  (UInt64(uu[6]) << 8) as UInt64
				|  UInt64(uu[7])
		}
	}
	
	public var serialize : Put {
		return Put.byWritingBytes(8) { buf in
			buf[0] = UInt8(truncatingBitPattern: self >> 56)
			buf[1] = UInt8(truncatingBitPattern: self >> 48)
			buf[2] = UInt8(truncatingBitPattern: self >> 40)
			buf[3] = UInt8(truncatingBitPattern: self >> 32)
			buf[4] = UInt8(truncatingBitPattern: self >> 24)
			buf[5] = UInt8(truncatingBitPattern: self >> 16)
			buf[6] = UInt8(truncatingBitPattern: self >> 8)
			buf[7] = UInt8(truncatingBitPattern: self)
		}
	}
}

extension UInt : Serializable {
	public static func deserialize<R>() -> Get<UInt, R> {
	#if (arch(x86_64) || arch(arm64))
		return UInt64.deserialize().map { UInt($0) }
	#else
		return UInt32.deserialize().map { UInt($0) }
	#endif
	}
	
	public var serialize : Put {
	#if (arch(x86_64) || arch(arm64))
		return UInt64(bitPattern: Int64(self)).serialize
	#else
		return UInt32(bitPattern: Int32(self)).serialize
	#endif
	}
}

extension Float : Serializable {
	public static func deserialize<R>() -> Get<Float, R> {
		return UInt32.deserialize().map { unsafeBitCast($0, to: Float.self) }
	}
	
	public var serialize : Put {
		return unsafeBitCast(self, to: UInt32.self).serialize
	}
}

extension Double : Serializable {
	public static func deserialize<R>() -> Get<Double, R> {
		return UInt64.deserialize().map { unsafeBitCast($0, to: Double.self) }
	}
	
	public var serialize : Put {
		return unsafeBitCast(self, to: UInt64.self).serialize
	}
}

extension String : Serializable {
	public static func deserialize<R>() -> Get<String, R> {
		return Int.deserialize().flatMap { n in
			return Get.byReadingBytes(n) { s in
				return String(cString: s.map { Int8(bitPattern: $0) })
			} 
		}
	}
	
	public var serialize : Put {
		return self.utf8.count.serialize 
			.putByteString(ByteString(self.utf8))
	}
}
