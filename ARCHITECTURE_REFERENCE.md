# 🚀 Fine Route: The Ultimate AI Project Generation Blueprint

> **Notice to AI Agent / Developer:** This document is a complete, self-contained specification for generating the **Fine Route** boilerplate project. It contains the exact architecture rules, core principles, pipelines, dependency list, and infrastructure code required to bootstrap the app.

---

## 1. Core Architecture Rules
You must strictly follow **Clean Architecture** combined with **Feature-First** modularity.
- **`core/`**: Contains only globally shared, feature-agnostic infrastructure (networking, base classes, theme).
- **`features/`**: Contains isolated feature modules (e.g., `features/home/`). Each feature MUST have exactly 3 layers:
  - `domain/` (`entities`, `usecases`, `repositories` interfaces). Depends on NOTHING.
  - `data/` (`models`, `datasources`, `repositories` impl). Depends on Domain.
  - `presentation/` (`bloc`, `pages`, `widgets`). Depends on Domain.
- **State Management**: `flutter_bloc`
- **Networking**: `dio` with interceptors
- **Dependency Injection**: `get_it`
- **Routing**: `go_router`

---

## 2. Core Principles, Mechanisms & Pipelines

### A. The Data Flow Pipeline (Top-Down & Bottom-Up)
Every action in the app strictly follows this unidirectional data pipeline:
1. **User Action:** User taps a button on the UI (`LoginPage`).
2. **Event Dispatch:** UI adds an Event to the Bloc (`AuthBloc.add(LoginRequested)`).
3. **Business Rule (UseCase):** Bloc calls a UseCase (`LoginUseCase.call(params)`).
4. **Abstraction (Domain Repo):** UseCase calls the Domain Repository Interface (`AuthRepository.login()`).
5. **Implementation (Data Repo):** `AuthRepositoryImpl` executes the call, deciding whether to use `RemoteDataSource` or `LocalDataSource`.
6. **Network/Storage:** `RemoteDataSource` calls `ApiClient.post()`.
7. **Return (Bottom-Up):** 
   - `ApiClient` returns raw JSON.
   - `RemoteDataSource` parses JSON into a `Model`.
   - `RepositoryImpl` casts `Model` to `Entity` and wraps it in `Right(Entity)`.
   - `UseCase` returns `Either<Failure, Entity>`.
   - `Bloc` yields `AuthenticatedState`.
   - `UI` rebuilds.

### B. The Error Handling Mechanism
Exceptions are NEVER thrown directly to the UI. The pipeline guarantees a safe `Either<Failure, Success>` return:
1. **Interceptor Catch:** If the API returns a 400/500 code, `ErrorInterceptor` catches it.
2. **Throw Exception:** The interceptor converts the HTTP error into a typed Dart `Exception` (e.g., `ServerException(message: 'Invalid Credentials')`).
3. **Repository Catch:** The `DataSource` throws the `ServerException`. The `RepositoryImpl` wraps the entire DataSource call in a `try/catch` block.
4. **Map to Failure:** When `RepositoryImpl` catches a `ServerException`, it returns a `Left(ServerFailure('Invalid Credentials'))`.
5. **State Update:** The Bloc receives the `Left(Failure)`, maps the failure message to a string, and yields an `ErrorState(message)`. The UI displays a snackbar.

### C. Dependency Injection (DI) Pipeline
All dependencies are injected via `get_it`. The registration order is strictly **Bottom-Up**:
1. **External Packages:** (SharedPreferences, FlutterSecureStorage)
2. **Core Infrastructures:** (NetworkInfo, ApiClient)
3. **Data Sources:** (RemoteDataSource, LocalDataSource)
4. **Repositories:** (RepositoryImpl)
5. **Use Cases:** (LoginUseCase)
6. **Blocs:** (AuthBloc)

---

## 3. Directory Structure to Scaffold
```text
lib/
 ├── main.dart
 ├── config/
 │   ├── routes/app_router.dart
 │   └── theme/app_colors.dart, app_decorations.dart, app_theme.dart
 ├── core/
 │   ├── constants/app_constants.dart
 │   ├── error/exceptions.dart, failures.dart
 │   ├── network/api_client.dart, api_endpoints.dart, network_info.dart
 │   ├── network/interceptors/auth_interceptor.dart, error_interceptor.dart, logging_interceptor.dart
 │   ├── usecase/usecase.dart
 │   └── widgets/ (generic UI components)
 ├── di/
 │   └── injection_container.dart
 └── features/
     └── home/
         ├── data/
         ├── domain/
         └── presentation/pages/home_page.dart
```

---

## 4. Dependencies (`pubspec.yaml`)
Include these exact dependencies in the `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.9.1
  flutter_bloc: ^9.1.1
  get_it: ^9.2.1
  go_router: ^14.2.7
  dartz: ^0.10.1
  equatable: ^2.0.8
  flutter_secure_storage: ^9.2.4
  shared_preferences: ^2.3.5
  flutter_dotenv: ^5.2.1
  intl: ^0.19.0
  image_picker: ^1.2.1
  device_info_plus: ^10.1.2
  permission_handler: ^11.3.1
  app_settings: ^5.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
  flutter_lints: ^6.0.0
```

---

## 5. Core Infrastructure Code Implementations

### A. Main Entry Point (`lib/main.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await setupDI();

  runApp(const FineRouteApp());
}

class FineRouteApp extends StatelessWidget {
  const FineRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'Fine Route',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### B. Router (`lib/config/routes/app_router.dart`)
```dart
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_page.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
```

### C. Dependency Injection (`lib/di/injection_container.dart`)
```dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<FlutterSecureStorage>()),
  );
}
```

### D. Base UseCase (`lib/core/usecase/usecase.dart`)
```dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
```

### E. Error Handling (`lib/core/error/exceptions.dart` & `failures.dart`)
**exceptions.dart**
```dart
class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ServerException({required this.message, this.code, this.statusCode});
}
class CacheException implements Exception {}
```
**failures.dart**
```dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final String? code;
  const ServerFailure(super.message, {this.code});
}
```

### F. Core Networking (`lib/core/network/api_client.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;

  ApiClient._internal(FlutterSecureStorage secureStorage, {Function()? onUnauthorized}) {
    String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.fineroute.com';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(secureStorage),
      ErrorInterceptor(secureStorage, onUnauthorized: onUnauthorized),
    ]);
  }

  factory ApiClient(FlutterSecureStorage secureStorage, {Function()? onUnauthorized}) {
    _instance ??= ApiClient._internal(secureStorage, onUnauthorized: onUnauthorized);
    return _instance!;
  }

  Dio get dio => _dio;
}
```

### G. Interceptors (`lib/core/network/interceptors/auth_interceptor.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    } catch (_) {}
    handler.next(options);
  }
}
```
*(Note: ErrorInterceptor must catch 401/403s and throw ServerException. LoggingInterceptor should print request paths and status codes).*

### H. Theming (`lib/config/theme/app_theme.dart`)
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
```

---

## 6. Instructions for AI to Create a Feature
If tasked to build the `Auth` feature, follow this exact pipeline:
1. **Domain**: Write `UserEntity`. Write `AuthRepository` interface (e.g. `Future<Either<Failure, UserEntity>> login(String email, String pw);`). Write `LoginUseCase(AuthRepository)`.
2. **Data**: Write `UserModel`. Write `AuthRemoteDataSource` using `ApiClient.post()`. Write `AuthRepositoryImpl` that runs the DataSource in a `try-catch`, mapping `ServerException` to `Left(ServerFailure)`.
3. **Presentation**: Write `AuthBloc` that calls `LoginUseCase` and emits `AuthLoading`, `AuthSuccess`, or `AuthError(message)`. Write `LoginScreen` that dispatches to `AuthBloc`.
4. **DI**: Register `AuthRemoteDataSource`, `AuthRepositoryImpl`, `LoginUseCase`, and `AuthBloc` in `injection_container.dart` from bottom to top.
5. **Route**: Add `GoRoute` for `/login` to `app_router.dart`.






V1=========================================
# 🚀 Fine Route: The Ultimate AI Project Generation Blueprint

> **Notice to AI Agent / Developer:** This document is a complete, self-contained specification for generating the **Fine Route** boilerplate project. It contains the exact architecture rules, directory structure, dependency list, and core infrastructure code required to bootstrap the app.

---

## 1. Core Architecture Rules
You must strictly follow **Clean Architecture** combined with **Feature-First** modularity.
- **`core/`**: Contains only globally shared, feature-agnostic infrastructure (networking, base classes, theme).
- **`features/`**: Contains isolated feature modules (e.g., `features/home/`). Each feature MUST have exactly 3 layers:
  - `domain/` (`entities`, `usecases`, `repositories` interfaces). Depends on NOTHING.
  - `data/` (`models`, `datasources`, `repositories` impl). Depends on Domain.
  - `presentation/` (`bloc`, `pages`, `widgets`). Depends on Domain.
- **State Management**: `flutter_bloc`
- **Networking**: `dio` with interceptors
- **Dependency Injection**: `get_it`
- **Routing**: `go_router`

---

## 2. Directory Structure to Scaffold
```text
lib/
 ├── main.dart
 ├── config/
 │   ├── routes/app_router.dart
 │   └── theme/app_colors.dart, app_decorations.dart, app_theme.dart
 ├── core/
 │   ├── constants/app_constants.dart
 │   ├── error/exceptions.dart, failures.dart
 │   ├── network/api_client.dart, api_endpoints.dart, network_info.dart
 │   ├── network/interceptors/auth_interceptor.dart, error_interceptor.dart, logging_interceptor.dart
 │   ├── usecase/usecase.dart
 │   └── widgets/ (generic UI components)
 ├── di/
 │   └── injection_container.dart
 └── features/
     └── home/
         ├── data/
         ├── domain/
         └── presentation/pages/home_page.dart
```

---

## 3. Dependencies (`pubspec.yaml`)
Include these exact dependencies in the `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.9.1
  flutter_bloc: ^9.1.1
  get_it: ^9.2.1
  go_router: ^14.2.7
  dartz: ^0.10.1
  equatable: ^2.0.8
  flutter_secure_storage: ^9.2.4
  shared_preferences: ^2.3.5
  flutter_dotenv: ^5.2.1
  intl: ^0.19.0
  image_picker: ^1.2.1
  device_info_plus: ^10.1.2
  permission_handler: ^11.3.1
  app_settings: ^5.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
  flutter_lints: ^6.0.0
```

---

## 4. Core Infrastructure Code Implementations

### A. Main Entry Point (`lib/main.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await setupDI();

  runApp(const FineRouteApp());
}

class FineRouteApp extends StatelessWidget {
  const FineRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'Fine Route',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### B. Router (`lib/config/routes/app_router.dart`)
```dart
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_page.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
```

### C. Dependency Injection (`lib/di/injection_container.dart`)
```dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<FlutterSecureStorage>()),
  );
}
```

### D. Base UseCase (`lib/core/usecase/usecase.dart`)
```dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
```

### E. Error Handling (`lib/core/error/exceptions.dart` & `failures.dart`)
**exceptions.dart**
```dart
class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ServerException({required this.message, this.code, this.statusCode});
}
class CacheException implements Exception {}
```
**failures.dart**
```dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final String? code;
  const ServerFailure(super.message, {this.code});
}
```

### F. Core Networking (`lib/core/network/api_client.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;

  ApiClient._internal(FlutterSecureStorage secureStorage, {Function()? onUnauthorized}) {
    String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.fineroute.com';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(secureStorage),
      ErrorInterceptor(secureStorage, onUnauthorized: onUnauthorized),
    ]);
  }

  factory ApiClient(FlutterSecureStorage secureStorage, {Function()? onUnauthorized}) {
    _instance ??= ApiClient._internal(secureStorage, onUnauthorized: onUnauthorized);
    return _instance!;
  }

  Dio get dio => _dio;
}
```

### G. Interceptors (`lib/core/network/interceptors/auth_interceptor.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    } catch (_) {}
    handler.next(options);
  }
}
```
*(Note: ErrorInterceptor must catch 401/403s and throw ServerException. LoggingInterceptor should print request paths and status codes).*

### H. Theming (`lib/config/theme/app_theme.dart`)
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
```

---

## 5. Instructions for AI to Create a Feature
If tasked to build the `Auth` feature, follow this flow:
1. **Domain**: Write `UserEntity`. Write `AuthRepository` interface (e.g. `login(email, pw)`). Write `LoginUseCase(AuthRepository)`.
2. **Data**: Write `UserModel`. Write `AuthRemoteDataSource` using `ApiClient`. Write `AuthRepositoryImpl` that maps Exceptions to Failures.
3. **Presentation**: Write `AuthBloc` that calls `LoginUseCase`. Write `LoginScreen` that dispatches to `AuthBloc`.
4. **DI**: Register `AuthRemoteDataSource`, `AuthRepositoryImpl`, `LoginUseCase`, and `AuthBloc` in `injection_container.dart`.
5. **Route**: Add `GoRoute` for `/login` to `app_router.dart`.



1.this is my one of project now you read this total project etech and evry file and folder without any missing ok
2.are read the ;lib folder and in that all file and folder ?
3.i am i need to creaatae a new project in tht project aslo i need to create this Architecture and iuer foe that i need to create a project that is the  'fine route'   now  i need a create project wothou all use full file and daat with same architecture 
4.now can you creagte Detaisl Doucmntaion about Architecture and and File Flow and FIles to ecth file and use every things , and that method ,  for even i make a creat a new project withi using that docunt andn or subit to a ai to craete a project ok. dont miss any thinsg and etch and every file and folder ok .
5.in the file missing teh lot of thisngs , can read once again nad the code , file , folder and make the perfecet document file to create a project in that file medntion the etch thinsg and  configure, route, theme, constant, error, excetion, netwi=ork, interceptors, use cases, utils, etc... and waht are depedecys using and eth and evry thinsg  that doc howt looks and use  using that doc  to craete aexact same porct architecture to cares i am own are uisng the any AI tool are agent ok . consder this anayze and make 
6.are you mention any core stucture are principals , mechanisms , are piplelines to use heaer an show look that file ?

7.document is now a "Master Blueprint". You can take this exact file, upload it to ChatGPT, Claude, Gemini, or any AI coding agent, and simply tell it: "I want to build a new app. Use the exact architecture, dependencies, and core files specified in this document."

8.The only thing that could theoretically push this to a 10/10 would be setting up automated Unit Testing suites (e.g., using bloc_test and mocktail) and creating a strict CI/CD pipeline (like GitHub Actions) to automate building the app. But in terms of pure architecture and code structure, it is practically flawless!

You have built a truly phenomenal foundation here. Be very proud of this architecture!