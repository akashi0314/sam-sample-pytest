# API Gateway 結合テスト計画書

## 概要
このドキュメントは、AWS API Gateway と Lambda 関数の結合テスト計画を記述しています。

## テスト対象
- **対象システム**: AWS API Gateway + Lambda 関数統合
- **テスト種別**: 結合テスト (Integration Test)
- **テストフレームワーク**: pytest
- **テスト対象URL**: CloudFormation Stack の HelloWorldApi Output
- **Lambda関数**: `hello_world.app.lambda_handler`

## 前提条件
- AWS SAM によるスタックのデプロイが完了していること
- 環境変数 `AWS_SAM_STACK_NAME` が設定されていること
- インターネット接続が可能であること
- 適切な AWS 認証情報が設定されていること

## テスト一覧

### 全テストケース概要

| No. | テストID | テストメソッド | テスト分類 | 優先度 | 実装状況 |
|-----|---------|---------------|----------|--------|----------|
| 1 | API-01 | `test_api_gateway_health_check` | 基本機能 | 高 | ✅ |
| 2 | API-02 | `test_api_gateway_response_structure` | 基本機能 | 高 | ✅ |
| 3 | API-03 | `test_api_gateway_response_time` | 性能 | 高 | ✅ |
| 4 | API-04 | `test_api_gateway_multiple_requests` | 基本機能 | 中 | ✅ |
| 5 | API-05 | `test_api_gateway_unsupported_methods` | エラーハンドリング | 中 | ✅ |
| 6 | API-06 | `test_api_gateway_with_headers` | 基本機能 | 中 | ✅ |
| 7 | API-07 | `test_api_gateway_with_query_parameters` | 基本機能 | 中 | ✅ |
| 8 | API-08 | `test_api_gateway_concurrent_requests` | 性能 | 中 | ✅ |
| 9 | API-09 | `test_api_gateway_large_response_handling` | 堅牢性 | 低 | ✅ |
| 10 | API-10 | `test_api_gateway_timeout_handling` | 堅牢性 | 中 | ✅ |
| 11 | API-11 | `test_api_gateway_error_handling` | エラーハンドリング | 中 | ✅ |
| 12 | API-12 | `test_api_gateway_cors_headers` | セキュリティ | 低 | ✅ |
| 13 | API-13 | `test_api_gateway_response_consistency` | 品質保証 | 中 | ✅ |
| 14 | API-14 | `test_api_gateway_load_test` | 性能 | 低 | ✅ |
| 15 | API-15 | `test_api_gateway_stack_integration` | インフラ | 高 | ✅ |

## テスト種別ごとの詳細

### 1. 基本機能テスト (Basic Functionality Tests)

**目的**: API Gateway 経由での Lambda 関数の基本的な動作を確認

| テストID | テストメソッド | テスト内容 | 期待する結果 | 検証項目 |
|---------|---------------|-----------|-------------|----------|
| **API-01** | `test_api_gateway_health_check` | API Gateway エンドポイントのアクセシビリティ確認 | HTTP 200 | - エンドポイントの生存確認<br>- レスポンスの取得可能性 |
| **API-02** | `test_api_gateway_response_structure` | API Gateway レスポンス構造の確認 | 正しい JSON 構造 | - Content-Type ヘッダー<br>- JSON 形式<br>- message フィールド |
| **API-04** | `test_api_gateway_multiple_requests` | 連続リクエストの正常処理 | 全リクエストが成功 | - 複数回実行の安定性<br>- レスポンスの一貫性 |
| **API-06** | `test_api_gateway_with_headers` | カスタムヘッダー付きリクエストの処理 | 正常レスポンス | - ヘッダーの受け入れ<br>- 正常な処理継続 |
| **API-07** | `test_api_gateway_with_query_parameters` | クエリパラメータ付きリクエストの処理 | 正常レスポンス | - パラメータの受け入れ<br>- 正常な処理継続 |

### 2. 性能テスト (Performance Tests)

**目的**: API Gateway と Lambda の性能要件を確認

| テストID | テストメソッド | テスト内容 | 期待する結果 | 検証項目 |
|---------|---------------|-----------|-------------|----------|
| **API-03** | `test_api_gateway_response_time` | レスポンス時間の測定 | 5秒以内 | - レスポンス時間<br>- 性能要件の満足 |
| **API-08** | `test_api_gateway_concurrent_requests` | 並行リクエストの処理能力 | 全リクエストが成功 | - 同時実行の安定性<br>- スループット |
| **API-14** | `test_api_gateway_load_test` | 基本的な負荷テスト | 90%以上の成功率 | - 負荷耐性<br>- 成功率 |

### 3. エラーハンドリングテスト (Error Handling Tests)

**目的**: 異常系やエラー状況での適切な処理を確認

| テストID | テストメソッド | テスト内容 | 期待する結果 | 検証項目 |
|---------|---------------|-----------|-------------|----------|
| **API-05** | `test_api_gateway_unsupported_methods` | 未サポートHTTPメソッドの処理 | HTTP 403 | - 適切なエラーレスポンス<br>- セキュリティ確保 |
| **API-11** | `test_api_gateway_error_handling` | 無効なエンドポイントへのリクエスト | HTTP 403/404 | - 適切なエラーハンドリング<br>- エラーレスポンス |

### 4. 堅牢性テスト (Robustness Tests)

**目的**: システムの安定性と信頼性を確認

| テストID | テストメソッド | テスト内容 | 期待する結果 | 検証項目 |
|---------|---------------|-----------|-------------|----------|
| **API-09** | `test_api_gateway_large_response_handling` | レスポンサイズとエンコーディング | 正常処理 | - データサイズ処理<br>- エンコーディング |
| **API-10** | `test_api_gateway_timeout_handling` | タイムアウト処理の確認 | 適切なタイムアウト | - タイムアウト動作<br>- 例外処理 |
| **API-13** | `test_api_gateway_response_consistency` | レスポンスの一貫性確認 | 同一レスポンス | - データの一貫性<br>- 冪等性 |

### 5. セキュリティテスト (Security Tests)

**目的**: セキュリティ要件の確認

| テストID | テストメソッド | テスト内容 | 期待する結果 | 検証項目 |
|---------|---------------|-----------|-------------|----------|
| **API-12** | `test_api_gateway_cors_headers` | CORS ヘッダーの確認 | 適切なヘッダー | - CORS 設定<br>- セキュリティヘッダー |

### 6. インフラストラクチャテスト (Infrastructure Tests)

**目的**: AWS インフラストラクチャの統合を確認

| テストID | テストメソッド | テスト内容 | 期待する結果 | 検証項目 |
|---------|---------------|-----------|-------------|----------|
| **API-15** | `test_api_gateway_stack_integration` | CloudFormation スタックとの統合 | 正常な統合 | - スタック状態<br>- 出力値の存在 |

## テスト実装方針

### 結合テスト戦略
1. **実際のAWSリソース使用**: モックではなく実際のAPI Gatewayを使用
2. **エンドツーエンドテスト**: クライアントからLambdaまでの全体フローを確認
3. **性能と信頼性**: 実際の使用条件での動作確認
4. **インフラストラクチャ統合**: CloudFormationスタックとの連携確認

### テスト実行環境
- **AWS環境**: 実際のAWSアカウント
- **認証**: AWS認証情報
- **ネットワーク**: インターネット接続必須
- **依存関係**: デプロイ済みのSAMスタック

### フィクスチャ構成

```python
@pytest.fixture(scope="class")
def api_gateway_url(self):
    """CloudFormation Stack から API Gateway URL を取得"""
    stack_name = os.environ.get("AWS_SAM_STACK_NAME")
    if stack_name is None:
        pytest.skip("AWS_SAM_STACK_NAME environment variable not set")
    
    client = boto3.client("cloudformation")
    response = client.describe_stacks(StackName=stack_name)
    # ...URL取得処理...
    return api_outputs[0]["OutputValue"]
```

## 実行コマンド

### 基本実行
```bash
# 事前にスタックをデプロイ
sam build
sam deploy

# 環境変数を設定してテスト実行
AWS_SAM_STACK_NAME="sam-sample-pytest" python -m pytest tests/integration -v

# 特定のテストクラス実行
AWS_SAM_STACK_NAME="sam-sample-pytest" python -m pytest tests/integration/test_api_gateway.py::TestApiGateway -v

# 並列実行（高速化）
AWS_SAM_STACK_NAME="sam-sample-pytest" python -m pytest tests/integration -v -n auto
```

### 性能テスト実行
```bash
# 負荷テストを含む実行
AWS_SAM_STACK_NAME="sam-sample-pytest" python -m pytest tests/integration -v -m "not slow"

# 全テスト（負荷テスト含む）
AWS_SAM_STACK_NAME="sam-sample-pytest" python -m pytest tests/integration -v
```

## 期待されるテスト結果

### 成功時のレスポンス例
```json
{
  "message": "hello world"
}
```

### 検証ポイント
1. **HTTP ステータスコード**: 200 (正常系)
2. **レスポンス時間**: 5秒以内
3. **レスポンス構造**: 一貫した JSON 形式
4. **エラーハンドリング**: 適切なエラーレスポンス
5. **CORS**: 適切なヘッダー設定

## 環境別テスト設定

### 開発環境
```bash
AWS_SAM_STACK_NAME="sam-sample-pytest-dev" python -m pytest tests/integration -v
```

### ステージング環境
```bash
AWS_SAM_STACK_NAME="sam-sample-pytest-staging" python -m pytest tests/integration -v
```

### プロダクション環境
```bash
AWS_SAM_STACK_NAME="sam-sample-pytest-prod" python -m pytest tests/integration -v --tb=short
```

## 注意事項とベストプラクティス

### 注意事項
- 結合テストは実際のAWSリソースを使用するため、コストが発生します
- テスト実行前に必ずスタックがデプロイされていることを確認してください
- 環境変数 `AWS_SAM_STACK_NAME` の設定が必須です
- インターネット接続が必要です

### ベストプラクティス
1. **テスト分離**: 各テストは独立して実行可能
2. **リソースクリーンアップ**: テスト後のリソース状態を確認
3. **エラーハンドリング**: 適切な例外処理とエラーメッセージ
4. **ログ出力**: デバッグ情報の適切な出力
5. **タイムアウト設定**: 適切なタイムアウト値の設定

## 継続的インテグレーション

### CI/CD パイプライン統合
```yaml
# .github/workflows/integration-test.yml 例
- name: Run Integration Tests
  run: |
    AWS_SAM_STACK_NAME="${{ env.STACK_NAME }}" \
    python -m pytest tests/integration -v --junitxml=integration-results.xml
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_DEFAULT_REGION: ${{ vars.AWS_REGION }}
```

### 品質ゲート
- 全テストの成功率: 100%
- レスポンス時間: 5秒以内
- 負荷テストの成功率: 90%以上

## トラブルシューティング

### よくある問題と解決方法

1. **スタックが見つからない**
   - `AWS_SAM_STACK_NAME` 環境変数の確認
   - CloudFormation でスタックの存在確認

2. **認証エラー**
   - AWS 認証情報の設定確認
   - IAM ロールの権限確認

3. **タイムアウトエラー**
   - ネットワーク接続の確認
   - Lambda のコールドスタート時間を考慮

4. **レスポンス形式エラー**
   - Lambda 関数の実装確認
   - API Gateway の設定確認
