// Please keep this file in alphabetical order!

// RUN: rm -rf %t
// RUN: mkdir %t
// RUN: %swift %clang-importer-sdk -module-cache-path %t/clang-module-cache -emit-module -o %t %s
// RUN: %swift %clang-importer-sdk -module-cache-path %t/clang-module-cache -parse-as-library %t/protocols.swiftmodule -parse -emit-objc-header-path %t/protocols.h
// RUN: FileCheck %s < %t/protocols.h
// RUN: FileCheck --check-prefix=NEGATIVE %s < %t/protocols.h
// RUN: %check-in-clang %t/protocols.h

import Foundation

// CHECK-LABEL: @protocol A{{$}}
// CHECK-NEXT: @end
@objc @class_protocol protocol A {}

// CHECK-LABEL: @protocol B <A>
// CHECK-NEXT: @end
@objc @class_protocol protocol B : A {}


// CHECK-LABEL: @protocol Methods{{$}}
// CHECK-NEXT: - (void)test;
// CHECK-NEXT: + (void)test2;
// CHECK-NEXT: - (void)testRawAnyTypes:(id)any other:(Class)other;
// CHECK-NEXT: - (void)testSingleProtocolTypes:(id <A>)a aAgain:(id <A>)a2 b:(id <B>)b bAgain:(id <B>)b2 both:(id <B>)both;
// CHECK-NEXT: - (void)testSingleProtocolClassTypes:(Class <A>)a aAgain:(Class <A>)a2 b:(Class <B>)b bAgain:(Class <B>)b2 both:(Class <B>)both;
// CHECK-NEXT: - (void)testComposition:(id <A, ZZZ>)x meta:(Class <A, ZZZ>)xClass;
// CHECK-NEXT: - (void)testOptional:(id <A>)opt meta:(Class <A>)m;
// CHECK-NEXT: @end
@objc @class_protocol protocol Methods {
  func test()
  class func test2()

  func testRawAnyTypes(any: AnyObject, other: AnyObject.Type)

  func testSingleProtocolTypes(a : A, aAgain a2: protocol<A>, b: B, bAgain b2: protocol<B>, both: protocol<A, B>)
  func testSingleProtocolClassTypes(a : A.Type, aAgain a2: protocol<A>.Type, b: B.Type, bAgain b2: protocol<B>.Type, both: protocol<A, B>.Type)
  func testComposition(x: protocol<A, ZZZ>, meta xClass: protocol<A, ZZZ>.Type)

  func testOptional(opt: A?, meta m: A.Type?)
}

// CHECK-LABEL: @interface MyObject : NSObject <NSCoding>
// CHECK-NEXT: init
// CHECK-NEXT: @end
// NEGATIVE-NOT: @protocol NSCoding
class MyObject : NSObject, NSCoding {
  init(coder aCoder: NSCoder) {
    super.init()
  }
}

// NEGATIVE-NOT: NotObjC
@class_protocol protocol NotObjC {}


// CHECK-LABEL: @interface NSString (SWIFT_EXTENSION(protocols)){{$}}
extension NSString : NotObjC {}

// CHECK-LABEL: @protocol ZZZ{{$}}
// CHECK-LABEL: @interface NSString (SWIFT_EXTENSION(protocols)) <A, ZZZ>
extension NSString : A, ZZZ {}

// CHECK-LABEL: @protocol Optional
// CHECK-NEXT: - (void)a;
// CHECK-NEXT: - (void)b;
// CHECK-NEXT: @optional
// CHECK-NEXT: - (void)c;
// CHECK-NEXT: - (void)d;
// CHECK-NEXT: @required
// CHECK-NEXT: - (void)e;
// CHECK-NEXT: @optional
// CHECK-NEXT: - (void)f;
// CHECK-NEXT: @end
@objc @class_protocol protocol Optional {
  func a()
  func b()

  @optional func c()
  @optional func d()

  func e()

  @optional func f()
}

// NEGATIVE-NOT: @protocol PrivateProto
@objc private protocol PrivateProto {}

// CHECK-LABEL: @interface PrivateProtoAdopter{{$}}
// CHECK-NEXT: init
// CHECK-NEXT: @end
@objc class PrivateProtoAdopter : PrivateProto {}

// CHECK-LABEL: @interface PrivateProtoAdopter2 <A>
// CHECK-NEXT: init
// CHECK-NEXT: @end
@objc class PrivateProtoAdopter2 : PrivateProto, A {}

// CHECK-LABEL: @protocol Properties
// CHECK-NEXT: @property (nonatomic, readonly) NSInteger a;
// CHECK-NEXT: @property (nonatomic) id <Properties> b;
// CHECK-NEXT: @optional
// CHECK-NEXT: @property (nonatomic, readonly, copy) NSString * c;
// CHECK-NEXT: @end
@objc @class_protocol protocol Properties {
  var a: Int { get }
  var b: Properties? { get set }
  @optional var c: String { get }
}


// CHECK-LABEL: @protocol ReversedOrder2{{$}}
// CHECK-NEXT: @end
// CHECK: SWIFT_PROTOCOL
// CHECK-NEXT: @protocol ReversedOrder1 <ReversedOrder2>
// CHECK-NEXT: @end
@objc @class_protocol protocol ReversedOrder1 : ReversedOrder2 {}
@objc @class_protocol protocol ReversedOrder2 {}


// CHECK-LABEL: @interface RootClass1{{$}}
// CHECK: @interface RootClass2 <A>{{$}}
// CHECK: @interface RootClass3 <B>{{$}}
@objc class RootClass1 : NotObjC {}
@objc class RootClass2 : A, NotObjC {}
@objc class RootClass3 : NotObjC, B {}

// CHECK: @interface RootClass4 <A, ZZZ>{{$}}
@objc class RootClass4 : A, ZZZ {}

// CHECK-LABEL: @interface Subclass : RootClass1 <ZZZ>{{$}}
@objc class Subclass : RootClass1, ZZZ {}

// Deliberately at the end of the file.
@objc @class_protocol protocol ZZZ {}
