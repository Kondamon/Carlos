import Foundation
import Quick
import Nimble
import Carlos
import PiedPiper

struct KeyTransformationsSharedExamplesContext {
  static let CacheToTest = "cache"
  static let InternalCache = "internalCache"
  static let Transformer = "transformer"
}

class KeyTransformationSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(_ configuration: Configuration) {
    sharedExamples("a fetch closure with transformed keys") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache: BasicCache<Int, Int>!
      var internalCache: CacheLevelFake<String, Int>!
      var transformer: OneWayTransformationBox<Int, String>!
      
      beforeEach {
        cache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.CacheToTest] as? BasicCache<Int, Int>
        internalCache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.InternalCache] as? CacheLevelFake<String, Int>
        transformer = sharedExampleContext()[KeyTransformationsSharedExamplesContext.Transformer] as? OneWayTransformationBox<Int, String>
      }
      
      context("when calling get") {
        var successValue: Int?
        var failureValue: Error?
        var fakeRequest: Promise<Int>!
        var canceled: Bool!
        
        beforeEach {
          canceled = false
          failureValue = nil
          successValue = nil
        }
        
        context("when the transformation closure returns a value") {
          let key = 12
          
          beforeEach {
            fakeRequest = Promise<Int>()
            internalCache.cacheRequestToReturn = fakeRequest.future
            
            cache.get(key).onSuccess { successValue = $0 }.onFailure { failureValue = $0 }.onCancel { canceled = true }
          }
          
          it("should forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledGet).to(equal(1))
          }
          
          it("should transform the key first") {
            var expected: String!
            transformer.transform(key).onSuccess { expected = $0 }
            expect(internalCache.didGetKey).to(equal(expected))
          }
          
          context("when the request succeeds") {
            let value = 101
            
            beforeEach {
              fakeRequest.succeed(value)
            }
            
            it("should call the original success closure") {
              expect(successValue).to(equal(value))
            }
            
            it("should not call the original failure closure") {
              expect(failureValue).to(beNil())
            }
            
            it("should not call the original cancel closure") {
              expect(canceled).to(beFalse())
            }
          }
          
          context("when the request is canceled") {
            beforeEach {
              fakeRequest.cancel()
            }
            
            it("should not call the original failure closure") {
              expect(failureValue).to(beNil())
            }
            
            it("should not call the original success closure") {
              expect(successValue).to(beNil())
            }
            
            it("should call the original cancel closure") {
              expect(canceled).to(beTrue())
            }
          }
          
          context("when the request fails") {
            let errorCode = TestError.anotherError
            
            beforeEach {
              fakeRequest.fail(errorCode)
            }
            
            it("should call the original failure closure") {
              expect(failureValue as? TestError).to(equal(errorCode))
            }
            
            it("should not call the original success closure") {
              expect(successValue).to(beNil())
            }
            
            it("should not call the original cancel closure") {
              expect(canceled).to(beFalse())
            }
          }
        }
        
        context("when the transformation closure returns nil") {
          let key = -12
          
          beforeEach {
            fakeRequest = Promise<Int>()
            internalCache.cacheRequestToReturn = fakeRequest.future
            
            cache.get(key).onSuccess { successValue = $0 }.onFailure { failureValue = $0 }
          }
          
          it("should not forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledGet).to(equal(0))
          }
          
          it("should not call the original success closure") {
            expect(successValue).to(beNil())
          }
          
          it("should not call the original cancel closure") {
            expect(canceled).to(beFalse())
          }
          
          it("should call the original failure closure") {
            expect(failureValue).notTo(beNil())
          }
          
          it("should pass the right error code") {
            expect(failureValue as? TestError).to(equal(TestError.simpleError))
          }
        }
      }
    }
    
    sharedExamples("a cache with transformed keys") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache: BasicCache<Int, Int>!
      var internalCache: CacheLevelFake<String, Int>!
      var transformer: OneWayTransformationBox<Int, String>!
      
      beforeEach {
        cache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.CacheToTest] as? BasicCache<Int, Int>
        internalCache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.InternalCache] as? CacheLevelFake<String, Int>
        transformer = sharedExampleContext()[KeyTransformationsSharedExamplesContext.Transformer] as? OneWayTransformationBox<Int, String>
      }
      
      itBehavesLike("a fetch closure with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
      
      context("when calling set") {
        var setSucceeded: Bool!
        var setError: Error?
        
        beforeEach {
          setSucceeded = false
          setError = nil
        }
        
        context("when the transformation closure returns a value") {
          let key = 10
          let value = 222
          
          beforeEach {
            cache.set(value, forKey: key).onSuccess {
              setSucceeded = true
            }.onFailure {
              setError = $0
            }
          }
          
          it("should forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledSet).to(equal(1))
          }
          
          it("should transform the key first") {
            var expected: String!
            transformer.transform(key).onSuccess { expected = $0 }
            expect(internalCache.didSetKey).to(equal(expected))
          }
          
          it("should pass the right value") {
            expect(internalCache.didSetValue).to(equal(value))
          }
          
          context("when the set succeeds") {
            beforeEach {
              internalCache.setPromisesReturned.first?.succeed(())
            }
            
            it("should succeed") {
              expect(setSucceeded).to(beTrue())
            }
          }
          
          context("when the set fails") {
            beforeEach {
              internalCache.setPromisesReturned.first?.fail(TestError.anotherError)
            }
            
            it("should fail") {
              expect(setError).notTo(beNil())
            }
            
            it("should pass the error through") {
              expect(setError as? TestError).to(equal(TestError.anotherError))
            }
          }
        }
        
        context("when the transformation closure fails") {
          let key = -10
          let value = 222
          
          beforeEach {
            cache.set(value, forKey: key).onSuccess {
              setSucceeded = true
            }.onFailure {
              setError = $0
            }
          }
          
          it("should not forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledSet).to(equal(0))
          }
          
          it("should fail") {
            expect(setError).notTo(beNil())
          }
          
          it("should pass the transformation error") {
            expect(setError as? TestError).to(equal(TestError.simpleError))
          }
        }
      }
      
      context("when calling clear") {
        beforeEach {
          cache.clear()
        }
        
        it("should forward the call to the internal cache") {
          expect(internalCache.numberOfTimesCalledClear).to(equal(1))
        }
      }
      
      context("when calling onMemoryWarning") {
        beforeEach {
          cache.onMemoryWarning()
        }
        
        it("should forward the call to the internal cache") {
          expect(internalCache.numberOfTimesCalledOnMemoryWarning).to(equal(1))
        }
      }
    }
  }
}

class KeyTransformationTests: QuickSpec {
  override func spec() {
    var cache: BasicCache<Int, Int>!
    var internalCache: CacheLevelFake<String, Int>!
    var transformer: OneWayTransformationBox<Int, String>!
    let transformationClosure: (Int) -> Future<String> = {
      let result = Promise<String>()
      if $0 > 0 {
        result.succeed("\($0 + 1)")
      } else {
        result.fail(TestError.simpleError)
      }
      return result.future
    }
    
    describe("Key transformation using a transformer and a cache, with the instance function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = internalCache.transformKeys(transformer)
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
  }
}
