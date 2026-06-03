## Input/Output Architecture

Each ViewModel defines clear Input and Output types:

```swift
@Observable
final class ProfileViewModel {
    // Input: Actions from View
    enum Input {
        case loadProfile
        case updateName(String)
        case saveChanges
    }
    
    // Output: State for View
    struct Output {
        var profile: Profile?
        var isLoading: Bool = false
        var error: Error?
    }
    
    private(set) var output = Output()
    
    func handle(_ input: Input) {
        switch input {
        case .loadProfile:
            loadProfile()
        case .updateName(let name):
            output.profile?.name = name
        case .saveChanges:
            saveChanges()
        }
    }
}
```

