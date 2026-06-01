# Contributing

## Branch Strategy

- `new-setup` — main development branch
- Feature branches: `feat/<name>`, `fix/<name>`, `refactor/<name>`

## Commit Convention

Use conventional commits:

```
feat: add new feature
fix: bug fix
refactor: code restructuring
chore: maintenance tasks
docs: documentation changes
perf: performance improvements
```

## Code Style

- **Dart**: Follow `flutter analyze` with no warnings.
- **Formatting**: Run `dart format .` before committing.
- **Naming**: `camelCase` for variables/functions, `PascalCase` for classes.

## Pull Request Process

1. Create feature branch from `new-setup`.
2. Make changes and test on device (Android + iOS + Web).
3. Run `flutter analyze` and `dart format .`.
4. Commit with conventional commit message.
5. Push and create PR against `new-setup`.

## Testing

- **Mobile**: Test on physical Android and iOS devices before merging.
- **Web**: Run `flutter build web --release` and test locally at `localhost:3000`.
- **Database**: Verify Supabase queries work with RLS policies.

## Web Performance & WASM Compatibility

When making web-related changes:

1. Run `flutter build web --wasm --release`.
2. Ensure Vercel routing configuration (`vercel.json`) has headers enabled for WebAssembly:
   - `Cross-Origin-Embedder-Policy: require-corp`
   - `Cross-Origin-Opener-Policy: same-origin`
3. Run Lighthouse audit on local build (`npx serve build/web` or deploy to Vercel preview).
4. Update `web_bundle_report.md` if significant changes occur.

### Image Loading Convention (`SafeWasmImage`)

To prevent runtime errors under the Dart WebAssembly (WASM) GC compiler toolchain:
- **Do NOT** use `CachedNetworkImage` directly in standard UI screens or widgets. It uses legacy JS-interop libraries that crash under WASM.
- **DO** use `SafeWasmImage` from `lib/widgets/wasm_image.dart`. It automatically loads images natively via `Image.network` under Web/WASM, and safely delegates to `CachedNetworkImage` on Mobile platforms (Android/iOS) to preserve offline caching features.

### Deferred Imports (Bundle Splitting)

Heavy packages used only on specific user actions should use Dart's `deferred as` imports:

```dart
import 'package:heavy_pkg/heavy_pkg.dart' deferred as heavy;

// Await loadLibrary() before first use
await heavy.loadLibrary();
heavy.SomeWidget();
```

This splits the package into a separate `.part.js` chunk loaded on demand, reducing initial `main.dart.js` size. Current deferred packages: `pdf` (`report_service.dart`), `printing` (`report_service.dart`), `csv` (`report_service.dart`), `flutter_map` (`checkout_screen.dart`).

Known constraints:
- Deferred namespaces cannot be used in `const` expressions.
- `loadLibrary()` must be awaited before constructing any objects from a deferred library.
- Transitive dependencies are automatically pulled into the deferred chunk.

### Renderer

The app compiles targeting **WebAssembly (WASM)** (`flutter build web --wasm`). This achieves high-performance rendering (using CanvasKit/Skwasm) while removing JS execution from the main browser UI thread, reducing Total Blocking Time (TBT).

## Environment Setup

1. Copy `.env.example` to `assets/.env`.
2. Run `flutter pub get`.
3. Run `dart run build_runner build` if schema changes.

## Key Files

| File | Purpose |
|------|---------|
| `lib/services/schema.prisma` | Database schema (source of truth) |
| `lib/main.dart` | App entry point |
| `web/index.html` | Web entry point |
| `vercel.json` | Deployment config |
| `web_bundle_report.md` | Web performance baseline |
| `implementation_plan.md` | Optimization roadmap |
| `changelog.md` | Version history |
