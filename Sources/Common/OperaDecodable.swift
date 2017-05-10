//  OperaDecodable.swift
//  Opera ( https://github.com/xmartlabs/Opera )
//
//  Copyright (c) 2016 Xmartlabs SRL ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
 *  Entities that conforms to OperaDecotable are able to 
    convert a AnyObject to itself. Notice that Opera 
    expects its entities to conform to this protocol. 
    OperaDecodable allows us to use the JSON parsing library
    that we feel confortable with.
 *  For instance to use Decodable we just need 
    to declare protocol conformance since Decodable 
    protocol methods are the same as OperaDecodable protocol.
 *  In order to use Argo as JSON parsing library each json 
    parseable entity should declare OperaDecodable protocol conformance. 
    We also need to implement `static func decode(json: AnyObject) throws -> Self` 
    to each argo parseable entity and probably the most elegant way is through
    protocol extensions as shown bellow.
 *
 *      extension Argo.Decodable where Self.DecodedType == Self, Self: OperaDecodable {
 *          static func decode(json: AnyObject) throws -> Self {
 *              let decoded = decode(JSON.parse(json))
 *              switch decoded {
 *              case .success(let value):
 *                  return value
 *              case .failure(let error):
 *                  throw error
 *              }
 *          }
 *      }
 */
public protocol OperaDecodable {

    static func decode(_ json: Any) throws -> Self

}

extension Dictionary where Key: OperaDecodable, Value: OperaDecodable {

    public static func decode(_ json: Any) throws -> Dictionary {
        return try Dictionary.decoder(key: Key.decode, value: Value.decode)(json)
    }

}

extension Array where Element: OperaDecodable {

    public static func decode(_ json: Any, ignoreInvalidObjects: Bool = false) throws -> [Element] {
        if ignoreInvalidObjects {
            return try [Element?].decoder { try? Element.decode($0) }(json).flatMap {$0}
        } else {
            return try Array.decoder(Element.decode)(json)
        }
    }

}

extension Array {

    public static func decoder(_ elementDecoder: @escaping (Any) throws -> Element) -> (Any) throws -> [Element] {
        return { json in
            return try NSArray.decode(json).map { try elementDecoder($0) }
        }
    }

}

extension Dictionary {

    public static func decoder(key keyDecoder: @escaping (Any) throws -> Key, value valueDecoder: @escaping (Any) throws -> Value) -> (Any) throws -> Dictionary {
        return { json in
            var dict = Dictionary()
            for (key, value) in try NSDictionary.decode(json) {
                try dict[keyDecoder(key)] = valueDecoder(value)
            }
            return dict
        }
    }

}

public func cast<T>(_ object: Any) throws -> T {

    guard let result = object as? T else {
//        let metadata = DecodingError.Metadata(object: object)
        throw NSError.init()//DecodingError.typeMismatch(expected: T.self, actual: type(of: object), metadata)
    }
    return result

}

extension NSDictionary: OperaDecodable {

    public static func decode(_ json: Any) throws -> Self {
        return try cast(json)
    }

}

extension NSArray {

    public static var decoder: (Any) throws -> NSArray = { try cast($0) }

    public static func decode(_ json: Any) throws -> NSArray {
        return try decoder(json)
    }

}
