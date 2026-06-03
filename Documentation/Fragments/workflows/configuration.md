## Configuration

iFoundation uses a centralized configuration system. Projects can be configured via:

1. **Interactive wizard**: `ifoundation create MyApp --interactive`
2. **Command-line flags**: `ifoundation create MyApp --template ios-app`
3. **Configuration file**: `.foundation/config.yml`

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `template` | Project template | `ios-app` |
| `minimumOSVersion` | Minimum OS version | `17.0` |
| `useSwiftUI` | Include SwiftUI | `true` |
| `enableAccessibility` | Enable a11y enforcement | `true` |
| `enableLocalization` | Enable localization | `true` |
| `targetLanguages` | Supported languages | `["en"]` |
| `includeUnitTests` | Include unit tests | `true` |
| `includeUITests` | Include UI tests | `true` |
| `ciProvider` | CI/CD provider | `github-actions` |
| `enableImmunity` | Enable immunity system | `true` |

