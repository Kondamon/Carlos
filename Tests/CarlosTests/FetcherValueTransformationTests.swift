import Foundation
import Quick
import Nimble
import Carlos
import PiedPiper

struct FetcherValueTransformationsSharedExamplesContext {
  static let FetcherToTest = "fetcher"
  static let InternalFetcher = "internalFetcher"
  static let Transformer = "transformer"
}

class FetcherValueTransformationSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(_ configuration: Configuration) {
    sharedExamples("a fetch closure with transformed values") { (sharedExampleContext: @escaping SharedExampleContext) in
      var fetcher: BasicFetcher<String, String>!
      var internalFetcher: FetcherFake<String, Int>!
      var transformer: OneWayTransformationBox<Int, String>!
      
      beforeEach {
        fetcher = sharedExampleContext()[FetcherValueTransformationsSharedExamplesContext.FetcherToTest] as? BasicFetcher<String, String>
        internalFetcher = sharedExampleContext()[FetcherValueTransformationsSharedExamplesContext.InternalFetcher] as? FetcherFake<String, Int>
        transformer = sharedExampleContext()[FetcherValueTransformationsSharedExamplesContext.Transformer] as? OneWayTransformationBox<Int, String>
      }
      
      context("when calling get") {
        let key = "12"
        var successValue: String?
        var failureValue: Error?
        var fakeRequest: Promise<Int>!
        
        beforeEach {
          fakeRequest = Promise<Int>()
          internalFetcher.cacheRequestToReturn = fakeRequest.future
          
          fetcher.get(key).onSuccess { successValue = $0 }.onFailure { failureValue = $0 }
        }
        
        it("should forward the call to the internal cache") {
          expect(internalFetcher.numberOfTimesCalledGet).to(equal(1))
        }
        
        it("should pass the right key") {
          expect(internalFetcher.didGetKey).to(equal(key))
        }
        
        context("when the request succeeds") {
          context("when the value can be successfully transformed") {
            let value = 101
            
            beforeEach {
              fakeRequest.succeed(value)
            }
            
            it("should call the original success closure") {
              expect(successValue).notTo(beNil())
            }
            
            it("should transform the value") {
              var expected: String!
              transformer.transform(value).onSuccess { expected = $0 }
              expect(successValue).to(equal(expected))
            }
          }
          
          context("when the value transformation returns nil") {
            let value = -101
            
            beforeEach {
              successValue = nil
              fakeRequest.succeed(value)
            }
            
            it("should not call the original success closure") {
              expect(successValue).to(beNil())
            }
            
            it("should call the original failure closure") {
              expect(failureValue).notTo(beNil())
            }
            
            it("should fail with the right code") {
              expect(failureValue as? TestError).to(equal(TestError.simpleError))
            }
          }
        }
        
        context("when the request fails") {
          let errorCode = TestError.anotherError
          
          beforeEach {
            fakeRequest.fail(errorCode)
          }
          
          it("should call the original failure closure") {
            expect(failureValue).notTo(beNil())
          }
          
          it("should fail with the right code") {
            expect(failureValue as? TestError).to(equal(errorCode))
          }
        }
      }
    }
  }
}

class FetcherValueTransformationTests: QuickSpec {
  override func spec() {
    var fetcher: BasicFetcher<String, String>!
    var internalFetcher: FetcherFake<String, Int>!
    var transformer: OneWayTransformationBox<Int, String>!
    let forwardTransformationClosure: (Int) -> Future<String> = {
      let result = Promise<String>()
      if $0 > 0 {
        result.succeed("\($0 + 1)")
      } else {
        result.fail(TestError.simpleError)
      }
      return result.future
    }
    
    describe("Value transformation using a transformer and a fetcher, with the instance function") {
      beforeEach {
        internalFetcher = FetcherFake<String, Int>()
        transformer = OneWayTransformationBox(transform: forwardTransformationClosure)
        fetcher = internalFetcher.transformValues(transformer)
      }
      
      itBehavesLike("a fetch closure with transformed values") {
        [
          FetcherValueTransformationsSharedExamplesContext.FetcherToTest: fetcher,
          FetcherValueTransformationsSharedExamplesContext.InternalFetcher: internalFetcher,
          FetcherValueTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
  }
}
