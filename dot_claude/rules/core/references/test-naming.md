# 言語別テスト命名規則

テスト名には3要素を含める：
1. **何を**（対象の機能/メソッド）
2. **どういう条件で**（入力/状態）
3. **どうなるか**（期待する結果）

## TypeScript / React

```typescript
describe('UserService', () => {
  it('returns user when valid ID is provided', () => { ... });
  it('throws error when user not found', () => { ... });
});
```

## Go

```go
// Test関数Should結果When条件
func TestUserRepositoryFindByIDShouldReturnUserWhenExists(t *testing.T) { ... }
func TestCalculateTotalShouldReturnZeroWhenCartIsEmpty(t *testing.T) { ... }
```

## Rust

```rust
// 関数_returns結果_when条件
#[test]
fn user_repository_find_by_id_returns_user_when_exists() { ... }

#[test]
fn calculate_total_returns_zero_when_cart_is_empty() { ... }
```

## Dart / Flutter

テスト名は**日本語**で記述する。`group` + `test` パターンを使用：

```dart
group('TaskDao', () {
  group('insertTask', () {
    test('有効なデータの場合にタスクを挿入できる', () async { ... });
    test('重複IDの場合に例外を投げる', () async { ... });
  });

  group('findTaskById', () {
    test('存在するIDの場合にタスクを返す', () async { ... });
    test('存在しないIDの場合にnullを返す', () async { ... });
  });
});
```

パターン: `'メソッド名 で条件の場合に期待結果'` または `'条件の場合に期待結果'`
