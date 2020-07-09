import Foundation
import Quick
import Nimble
import Carlos
import PiedPiper

struct ComposedCacheSharedExamplesContext {
  static let CacheToTest = "composedCache"
  static let FirstComposedCache = "cache1"
  static let SecondComposedCache = "cache2"
}

class CompositionSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(_ configuration: Configuration) {
    sharedExamples("get without considering set calls") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      context("when calling get") {
        let key = "test key"
        var cache1Request: Promise<Int>!
        var cache2Request: Promise<Int>!
        var successSentinel: Bool?
        var failureSentinel: Bool?
        var cancelSentinel: Bool!
        var successValue: Int?
        
        beforeEach {
          cancelSentinel = false
          successSentinel = nil
          successValue = nil
          failureSentinel = nil
          
          cache1Request = Promise<Int>()
          cache1.cacheRequestToReturn = cache1Request.future
          
          cache2Request = Promise<Int>()
          cache2.cacheRequestToReturn = cache2Request.future
          
          for cache in [cache1, cache2] {
            cache?.numberOfTimesCalledGet = 0
            cache?.numberOfTimesCalledSet = 0
          }
          
          composedCache.get(key)
            .onSuccess { result in
              successSentinel = true
              successValue = result
            }.onFailure { _ in
              failureSentinel = true
            }.onCancel {
              cancelSentinel = true
            }
        }
        
        it("should not call any success closure") {
          expect(successSentinel).to(beNil())
        }
        
        it("should not call any failure closure") {
          expect(failureSentinel).to(beNil())
        }
        
        it("should not call any cancel closure") {
          expect(cancelSentinel).to(beFalse())
        }
        
        it("should call get on the first cache") {
          expect(cache1.numberOfTimesCalledGet).to(equal(1))
        }
        
        it("should not call get on the second cache") {
          expect(cache2.numberOfTimesCalledGet).to(equal(0))
        }
        
        context("when the first request succeeds") {
          let value = 1022
          
          beforeEach {
            cache1Request.succeed(value)
          }
          
          it("should call the success closure") {
            expect(successSentinel).notTo(beNil())
          }
          
          it("should pass the right value") {
            expect(successValue).to(equal(value))
          }
          
          it("should not call the failure closure") {
            expect(failureSentinel).to(beNil())
          }
          
          it("should not call the cancel closure") {
            expect(cancelSentinel).to(beFalse())
          }
          
          it("should not call get on the second cache") {
            expect(cache2.numberOfTimesCalledGet).to(equal(0))
          }
        }
        
        context("when the first request is canceled") {
          beforeEach {
            cache1Request.cancel()
          }
          
          it("should not call the success closure") {
            expect(successSentinel).to(beNil())
          }
          
          it("should not call the failure closure") {
            expect(failureSentinel).to(beNil())
          }
          
          it("should call the cancel closure") {
            expect(cancelSentinel).to(beTrue())
          }
        }
        
        context("when the first request fails") {
          beforeEach {
            cache1Request.fail(TestError.simpleError)
          }
          
          it("should not call the success closure") {
            expect(successSentinel).to(beNil())
          }
          
          it("should not call the failure closure") {
            expect(failureSentinel).to(beNil())
          }
          
          it("should not call the cancel closure") {
            expect(cancelSentinel).to(beFalse())
          }
          
          it("should call get on the second cache") {
            expect(cache2.numberOfTimesCalledGet).to(equal(1))
          }
          
          it("should not do other get calls on the first cache") {
            expect(cache1.numberOfTimesCalledGet).to(equal(1))
          }
          
          context("when the second request succeeds") {
            let value = -122
            
            beforeEach {
              cache2Request.succeed(value)
            }
            
            it("should call the success closure") {
              expect(successSentinel).notTo(beNil())
            }
            
            it("should pass the right value") {
              expect(successValue).to(equal(value))
            }
            
            it("should not call the failure closure") {
              expect(failureSentinel).to(beNil())
            }
            
            it("should not call the cancel closure") {
              expect(cancelSentinel).to(beFalse())
            }
          }
          
          context("when the second request is canceled") {
            beforeEach {
              cache2Request.cancel()
            }
            
            it("should not call the success closure") {
              expect(successSentinel).to(beNil())
            }
            
            it("should not call the failure closure") {
              expect(failureSentinel).to(beNil())
            }
            
            it("should call the cancel closure") {
              expect(cancelSentinel).to(beTrue())
            }
          }
          
          context("when the second request fails") {
            beforeEach {
              cache2Request.fail(TestError.simpleError)
            }
            
            it("should not call the success closure") {
              expect(successSentinel).to(beNil())
            }
            
            it("should call the failure closure") {
              expect(failureSentinel).notTo(beNil())
            }
            
            it("should not call the cancel closure") {
              expect(cancelSentinel).to(beFalse())
            }
            
            it("should not do other get calls on the first cache") {
              expect(cache1.numberOfTimesCalledGet).to(equal(1))
            }
            
            it("should not do other get calls on the second cache") {
              expect(cache2.numberOfTimesCalledGet).to(equal(1))
            }
          }
        }
      }
    }
    
    sharedExamples("get on caches") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      context("when calling get") {
        let key = "test key"
        var cache1Request: Promise<Int>!
        var cache2Request: Promise<Int>!
        
        beforeEach {
          cache1Request = Promise<Int>()
          cache1.cacheRequestToReturn = cache1Request.future
          
          cache2Request = Promise<Int>()
          cache2.cacheRequestToReturn = cache2Request.future
          
          for cache in [cache1, cache2] {
            cache?.numberOfTimesCalledGet = 0
            cache?.numberOfTimesCalledSet = 0
          }
          
          _ = composedCache.get(key)
        }
        
        itBehavesLike("get without considering set calls") {
          [
            ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
            ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
            ComposedCacheSharedExamplesContext.CacheToTest: composedCache
          ]
        }
        
        context("when the first request fails") {
          beforeEach {
            cache1Request.fail(TestError.simpleError)
          }
          
          context("when the second request succeeds") {
            let value = -122
            
            beforeEach {
              cache2Request.succeed(value)
            }
            
            it("should set the value on the first cache") {
              expect(cache1.numberOfTimesCalledSet).to(equal(1))
            }
            
            it("should set the value on the first cache with the right key") {
              expect(cache1.didSetKey).to(equal(key))
            }
            
            it("should set the right value on the first cache") {
              expect(cache1.didSetValue).to(equal(value))
            }
            
            it("should not set the same value again on the second cache") {
              expect(cache2.numberOfTimesCalledSet).to(equal(0))
            }
          }
        }
      }
    }
    
    sharedExamples("both caches are caches") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      itBehavesLike("first cache is a cache") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
      
      itBehavesLike("second cache is a cache") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
      
      context("when calling set") {
        let key = "this key"
        let value = 102
        var succeeded: Bool!
        var failed: Error?
        var canceled: Bool!
        
        beforeEach {
          succeeded = false
          failed = nil
          canceled = false
          
          composedCache.set(value, forKey: key)
            .onSuccess { _ in succeeded = true }
            .onFailure { failed = $0 }
            .onCancel { canceled = true }
        }
        
        it("should call set on the first cache") {
          expect(cache1.numberOfTimesCalledSet).to(equal(1))
        }
        
        it("should pass the right key on the first cache") {
          expect(cache1.didSetKey).to(equal(key))
        }
        
        it("should pass the right value on the first cache") {
          expect(cache1.didSetValue).to(equal(value))
        }
        
        context("when the set closure succeeds") {
          beforeEach {
            cache1.setPromisesReturned[0].succeed(())
          }
          
          it("should call set on the second cache") {
            expect(cache2.numberOfTimesCalledSet).to(equal(1))
          }
          
          it("should pass the right key on the second cache") {
            expect(cache2.didSetKey).to(equal(key))
          }
          
          it("should pass the right value on the second cache") {
            expect(cache2.didSetValue).to(equal(value))
          }
          
          context("when the set closure succeeds") {
            beforeEach {
              cache2.setPromisesReturned[0].succeed(())
            }
            
            it("should succeed the future") {
              expect(succeeded).to(beTrue())
            }
          }
          
          context("when the set clousure is canceled") {
            beforeEach {
              cache2.setPromisesReturned[0].cancel()
            }
            
            it("should cancel the future") {
              expect(canceled).to(beTrue())
            }
          }
          
          context("when the set closure fails") {
            let error = TestError.anotherError
            
            beforeEach {
              cache2.setPromisesReturned[0].fail(error)
            }
            
            it("should fail the future") {
              expect(failed as? TestError).to(equal(error))
            }
          }
        }
        
        context("when the set clousure is canceled") {
          beforeEach {
            cache1.setPromisesReturned[0].cancel()
          }
          
          it("should cancel the future") {
            expect(canceled).to(beTrue())
          }
        }
        
        context("when the set closure fails") {
          let error = TestError.anotherError
          
          beforeEach {
            cache1.setPromisesReturned[0].fail(error)
          }
          
          it("should fail the future") {
            expect(failed as? TestError).to(equal(error))
          }
        }
      }
    }
    
    sharedExamples("first cache is a cache") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      context("when calling set") {
        let key = "this key"
        let value = 102
        var failed: Error?
        var canceled: Bool!
        
        beforeEach {
          failed = nil
          canceled = false
          
          composedCache.set(value, forKey: key)
            .onSuccess { _ in }
            .onFailure { failed = $0 }
            .onCancel { canceled = true }
        }
        
        it("should call set on the first cache") {
          expect(cache1.numberOfTimesCalledSet).to(equal(1))
        }
        
        it("should pass the right key on the first cache") {
          expect(cache1.didSetKey).to(equal(key))
        }
        
        it("should pass the right value on the first cache") {
          expect(cache1.didSetValue).to(equal(value))
        }
        
        context("when the set clousure is canceled") {
          beforeEach {
            cache1.setPromisesReturned[0].cancel()
          }
          
          it("should cancel the future") {
            expect(canceled).to(beTrue())
          }
        }
        
        context("when the set closure fails") {
          let error = TestError.anotherError
          
          beforeEach {
            cache1.setPromisesReturned[0].fail(error)
          }
          
          it("should fail the future") {
            expect(failed as? TestError).to(equal(error))
          }
        }
      }
      
      context("when calling clear") {
        beforeEach {
          composedCache.clear()
        }
        
        it("should call clear on the first cache") {
          expect(cache1.numberOfTimesCalledClear).to(equal(1))
        }
      }
      
      context("when calling onMemoryWarning") {
        beforeEach {
          composedCache.onMemoryWarning()
        }
        
        it("should call onMemoryWarning on the first cache") {
          expect(cache1.numberOfTimesCalledOnMemoryWarning).to(equal(1))
        }
      }
    }
    
    sharedExamples("second cache is a cache") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache2: CacheLevelFake<String, Int>!
      var cache1: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
          
      context("when calling set") {
        let key = "this key"
        let value = 102
        var succeeded: Bool!
        var failed: Error?
        var canceled: Bool!
        
        beforeEach {
          succeeded = false
          failed = nil
          canceled = false
          
          composedCache.set(value, forKey: key)
            .onSuccess { _ in succeeded = true }
            .onFailure { failed = $0 }
            .onCancel { canceled = true }
        }
        
        it("should call set on the second cache") {
          expect(cache2.numberOfTimesCalledSet).to(equal(1))
        }
        
        it("should pass the right key on the second cache") {
          expect(cache2.didSetKey).to(equal(key))
        }
        
        it("should pass the right value on the second cache") {
          expect(cache2.didSetValue).to(equal(value))
        }
        
        context("when the set closure succeeds") {
          beforeEach {
            cache1.setPromisesReturned.first?.succeed(())
            cache2.setPromisesReturned[0].succeed(())
          }
          
          it("should succeed the future") {
            expect(succeeded).to(beTrue())
          }
        }
        
        context("when the set clousure is canceled") {
          beforeEach {
            cache1.setPromisesReturned.first?.cancel()
            cache2.setPromisesReturned[0].cancel()
          }
          
          it("should cancel the future") {
            expect(canceled).to(beTrue())
          }
        }
        
        context("when the set closure fails") {
          let error = TestError.anotherError
          
          beforeEach {
            cache1.setPromisesReturned.first?.fail(error)
            cache2.setPromisesReturned[0].fail(error)
          }
          
          it("should fail the future") {
            expect(failed as? TestError).to(equal(error))
          }
        }
      }
      
      context("when calling clear") {
        beforeEach {
          composedCache.clear()
        }
        
        it("should call clear on the second cache") {
          expect(cache2.numberOfTimesCalledClear).to(equal(1))
        }
      }
      
      context("when calling onMemoryWarning") {
        beforeEach {
          composedCache.onMemoryWarning()
        }
        
        it("should call onMemoryWarning on the second cache") {
          expect(cache2.numberOfTimesCalledOnMemoryWarning).to(equal(1))
        }
      }
    }
    
    sharedExamples("a composition of two fetch closures") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      itBehavesLike("get without considering set calls") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
    }
    
    sharedExamples("a composition of a fetch closure and a cache") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      itBehavesLike("get without considering set calls") {
        [
        ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
        ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
        ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
      
      itBehavesLike("second cache is a cache") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
    }
    
    sharedExamples("a composition of a cache and a fetch closure") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }

      itBehavesLike("get on caches") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }

      itBehavesLike("first cache is a cache") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
    }
    
    sharedExamples("a composed cache") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cache1: CacheLevelFake<String, Int>!
      var cache2: CacheLevelFake<String, Int>!
      var composedCache: BasicCache<String, Int>!
      
      beforeEach {
        cache1 = sharedExampleContext()[ComposedCacheSharedExamplesContext.FirstComposedCache] as? CacheLevelFake<String, Int>
        cache2 = sharedExampleContext()[ComposedCacheSharedExamplesContext.SecondComposedCache] as? CacheLevelFake<String, Int>
        composedCache = sharedExampleContext()[ComposedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
      }
      
      itBehavesLike("get on caches") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
      
      itBehavesLike("both caches are caches") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
    }
  }
}

class CacheLevelCompositionTests: QuickSpec {
  override func spec() {
    var cache1: CacheLevelFake<String, Int>!
    var cache2: CacheLevelFake<String, Int>!
    var composedCache: BasicCache<String, Int>!
    
    describe("Cache composition using two cache levels with the instance function") {
      beforeEach {
        cache1 = CacheLevelFake<String, Int>()
        cache2 = CacheLevelFake<String, Int>()
        
        composedCache = cache1.compose(cache2)
      }
      
      itBehavesLike("a composed cache") {
        [
          ComposedCacheSharedExamplesContext.FirstComposedCache: cache1,
          ComposedCacheSharedExamplesContext.SecondComposedCache: cache2,
          ComposedCacheSharedExamplesContext.CacheToTest: composedCache
        ]
      }
    }
  }
}
