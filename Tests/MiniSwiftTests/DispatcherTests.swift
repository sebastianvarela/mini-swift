import XCTest
@testable import MiniSwift

final class DispatcherTests: XCTestCase {
    
    func test_subscription_count() {
        
        let dispatcher = Dispatcher()
        let cancellableBag = CancellableBag()
        
        XCTAssert(dispatcher.subscriptionCount == 0)
        
        dispatcher.subscribe { (action: OneTestAction) -> Void in }.cancelled(by: cancellableBag)
        dispatcher.subscribe { (action: OneTestAction) -> Void in }.cancelled(by: cancellableBag)
        
        print(dispatcher.subscriptionCount)
        
        XCTAssert(dispatcher.subscriptionCount == 2)
        
        cancellableBag.cancel()
        
        XCTAssert(dispatcher.subscriptionCount == 0)
    }
    
    func test_add_remove_middleware() {
        
        let dispatcher = Dispatcher()
        
        let middleware = TestMiddleware()
        
        dispatcher.add(middleware: middleware)
        
        dispatcher.dispatch(OneTestAction(counter: 0), mode: .sync)
        
        XCTAssert(middleware.actions(of: OneTestAction.self).isEmpty == false)
        
        middleware.clear()
        
        XCTAssert(middleware.actions(of: OneTestAction.self).isEmpty == true)
        
        dispatcher.remove(middleware: middleware)
        
        dispatcher.dispatch(OneTestAction(counter: 0), mode: .sync)
        
        XCTAssert(middleware.actions(of: OneTestAction.self).isEmpty == true)
    }
    
    func test_add_remove_service() {
        
        class TestService: Service {
            
            var id: UUID = UUID()
            
            var actions = [Action]()
            
            private let expectation: XCTestExpectation
            
            init(_ expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            var perform: ServiceChain { { action, _ -> Void in
                    self.actions.append(action)
                    self.expectation.fulfill()
                }
            }
        }
        
        let expectation = XCTestExpectation(description: "Service")
        
        let dispatcher = Dispatcher()
        
        let service = TestService(expectation)
        
        dispatcher.register(service: service)
        
        XCTAssert(service.actions.isEmpty == true)
        
        dispatcher.dispatch(OneTestAction(counter: 1), mode: .sync)
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssert(service.actions.count == 1)
        
        XCTAssert(service.actions.contains(where: { $0 is OneTestAction }) == true)
        
        dispatcher.unregister(service: service)
        
        service.actions.removeAll()
        
        dispatcher.dispatch(OneTestAction(counter: 1), mode: .sync)
        
        XCTAssert(service.actions.isEmpty == true)
        
    }
}
