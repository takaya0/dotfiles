# Flutter/Dart テストベストプラクティス

## テストファイル配置

**ミラーディレクトリ構造**: `lib/` の構造を `test/` にミラーリング。

```
lib/
  shared/
    database/
      task_dao.dart
    models/
      task.dart
test/
  shared/
    database/
      task_dao_test.dart
      fixtures/
        task_fixtures.dart
    models/
      task_test.dart
  helpers/
    pump_app.dart
    test_router.dart
```

## テスト命名規則

テスト名は**日本語**で記述する。3要素（何を、条件、結果）を含める。

```dart
group('TaskDao', () {
  group('insertTask', () {
    test('有効なデータの場合にタスクを挿入できる', () async { ... });
    test('重複IDの場合に例外を投げる', () async { ... });
  });
});

group('Task', () {
  test('fromMap で全フィールドを復元できる', () { ... });
  test('title が空の場合は例外', () { ... });
  test('copyWith で nullable フィールドを null にできる', () { ... });
});
```

## テストフレームワーク

- **flutter_test**: 標準テストフレームワーク
- **mocktail**: モックライブラリ（mockitoではない）
- **fake_async**: 非同期テスト用ヘルパー

## モック定義

```dart
import 'package:mocktail/mocktail.dart';

// モッククラスはテストファイル内にインラインで定義
class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
  });

  test('リポジトリからタスクを取得できる', () {
    // Arrange
    when(() => mockRepository.getById(any()))
        .thenAnswer((_) async => testTask);

    // Act
    final result = await mockRepository.getById(taskId);

    // Assert
    expect(result, equals(testTask));
    verify(() => mockRepository.getById(taskId)).called(1);
  });
}
```

## データベーステスト

インメモリSQLiteを使用（モックではない実DB）：

```dart
import 'package:drift/native.dart';

void main() {
  group('TaskDao', () {
    late AppDatabase database;
    late TaskDao dao;

    setUp(() {
      // Arrange: インメモリDBでAppDatabaseを初期化
      database = AppDatabase(NativeDatabase.memory());
      dao = database.taskDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('有効なデータの場合にタスクを挿入できる', () async {
      // Arrange
      final testTask = TaskTableCompanion.insert(
        id: 'task-123',
        userId: 'user-456',
        title: 'テストタスク',
        // ...
      );

      // Act
      await dao.insertTask(testTask);

      // Assert
      final result = await dao.findTaskById('task-123');
      expect(result, isNotNull);
      expect(result!.title, equals('テストタスク'));
    });
  });
}
```

## Widgetテスト

`pumpApp()` / `pumpWidget_()` ヘルパーを使用：

```dart
import '../helpers/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('初期表示でタイトルが表示される', (tester) async {
      // Arrange & Act
      await tester.pumpApp(const HomeScreen());

      // Assert
      expect(find.text('ホーム'), findsOneWidget);
    });
  });
}
```

## Providerテスト

`ProviderContainer` + `overrides` を使用：

```dart
void main() {
  group('TaskProvider', () {
    test('リポジトリからタスク一覧を取得できる', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final tasks = await container.read(taskListProvider.future);

      // Assert
      expect(tasks, hasLength(3));
    });
  });
}
```

## Routerテスト

`pumpAppWithRouter()` を使用：

```dart
import '../helpers/test_router.dart';

void main() {
  group('AppRouter', () {
    testWidgets('/ でHomeScreenに遷移する', (tester) async {
      await tester.pumpAppWithRouter('/');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

## フィクスチャ

ファクトリ関数を `test/shared/database/fixtures/` に配置：

```dart
// test/shared/database/fixtures/task_fixtures.dart
import 'package:task_flow_app/shared/models/models.dart';

final testTask = Task.create(
  userId: UserId('550e8400-e29b-41d4-a716-446655440000'),
  title: 'Test Task',
);

// カスタムフィクスチャはbuildTestXxx()パターン
Task buildTestTask({String title = 'Test Task', ...}) {
  return Task.create(title: title, ...);
}
```

## パフォーマンステスト

`@Tags(['performance'])` でタグ付け：

```dart
@Tags(['performance'])
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/performance_test_helper.dart';

void main() {
  group('TaskDao パフォーマンス', () {
    test('1000件挿入が1秒以内に完了する', () async {
      final result = await measurePerformance(() async {
        // ...
      });
      expect(result.duration, lessThan(Duration(seconds: 1)));
    });
  });
}
```

## テスト実行コマンド

```bash
# 全テスト実行
flutter test

# 単一ファイル実行
flutter test test/shared/database/task_dao_test.dart

# パフォーマンステスト除外
flutter test --exclude-tags performance

# パフォーマンステストのみ
flutter test --tags performance
```
