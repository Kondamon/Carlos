import Foundation
import Quick
import Nimble
import Carlos
import PiedPiper

class OneWayTransformationBoxTests: QuickSpec {
  override func spec() {
    describe("OneWayTransformationBox") {
      var box: OneWayTransformationBox<String, Int>!
      
      beforeEach {
        box = OneWayTransformationBox(transform: {
          Future(value: Int($0), error: TestError.simpleError)
        })
      }
      
      context("when using the transformation") {
        var result: Int!
        var error: Error!
        
        beforeEach {
          result = nil
          error = nil
        }
        
        context("if the transformation is possible") {
          let originString = "102"
          
          beforeEach {
            box.transform(originString)
              .onSuccess({ result = $0 })
              .onFailure({ error = $0 })
          }
          
          it("should call the success closure") {
            expect(result).notTo(beNil())
          }
          
          it("should not call the failure closure") {
            expect(error).to(beNil())
          }
          
          it("should return the expected result") {
            expect(result).to(equal(Int(originString)))
          }
        }
        
        context("if the transformation is not possible") {
          let originString = "10asd2"
          
          beforeEach {
            box.transform(originString)
              .onSuccess({ result = $0 })
              .onFailure({ error = $0 })
          }
          
          it("should not call the success closure") {
            expect(result).to(beNil())
          }
          
          it("should call the failure closure") {
            expect(error).notTo(beNil())
          }
          
          it("should pass the right error") {
            expect(error as? TestError).to(equal(TestError.simpleError))
          }
        }
      }
    }
  }
}
