# SAM Sample Pytest - 学習用リポジトリ

このリポジトリは、AWS SAM (Serverless Application Model) と pytest を使ったサーバーレス開発の学習を目的としたサンプルプロジェクトです。

## 📚 このリポジトリで学べること

- **AWS SAMの基本的な使い方**
  - Lambda関数の開発とデプロイ
  - API Gatewayとの連携
  - CloudFormationを使ったインフラ管理

- **pytestによるテスト手法**
  - 単体テスト（Unit Test）
  - 結合テスト（Integration Test）
  - テストカバレッジの測定

- **開発ワークフロー**
  - ローカル開発環境での動作確認
  - AWSクラウドへのデプロイ
  - 自動テストによる品質管理

## 🏗️ プロジェクト構成

```
sam-sample-pytest/
├── hello_world/                # Lambda関数のソースコード
│   ├── app.py                  # メインのLambda関数
│   └── requirements.txt        # Python依存関係
├── tests/                      # テストコード
│   ├── unit/                   # 単体テスト
│   └── integration/            # 結合テスト
├── template.yaml               # SAMテンプレート（AWSリソース定義）
├── scripts/                    # 自動化スクリプト
│   └── local-release.sh        # 開発用スクリプト
├── simple-test.sh              # 学習用ワンストップスクリプト
└── README.md                   # このファイル
```

## 🚀 はじめ方

### 必要な環境

- **Python 3.12** - プログラミング言語
- **AWS CLI** - AWSを操作するためのツール
- **SAM CLI** - サーバーレス開発用ツール
- **Docker** - ローカル実行用（推奨）

### 🎯 かんたんスタート（推奨）

初心者の方は、学習用スクリプトを使うことをお勧めします：

```bash
# 実行権限を付与
chmod +x simple-test.sh

# 全ステップを順番に実行（学習に最適）
./simple-test.sh

# または、個別にステップ実行
./simple-test.sh setup     # 環境確認
./simple-test.sh build     # ビルド+単体テスト
./simple-test.sh local     # ローカル動作確認
./simple-test.sh deploy    # AWSデプロイ+結合テスト
```

### 📝 手動での実行方法

#### 1. 環境セットアップ

```bash
# 必要なライブラリをインストール
pip install pytest pytest-cov boto3 requests

# AWS認証情報を設定
aws configure
```

#### 2. ローカル開発

```bash
# アプリケーションをビルド
sam build

# 単体テストを実行
pytest tests/unit/ -v

# ローカルでLambda関数を実行
sam local invoke HelloWorldFunction --event events/event.json

# ローカルAPIサーバーを起動
sam local start-api
# ブラウザで http://localhost:3000/hello にアクセス
```

#### 3. AWSへのデプロイ

```bash
# 初回デプロイ（設定を行います）
sam deploy --guided

# 2回目以降のデプロイ
sam deploy
```

#### 4. 結合テストの実行

```bash
# 環境変数を設定して結合テストを実行
AWS_SAM_STACK_NAME="sam-sample-pytest" pytest tests/integration/ -v
```

## 🧪 テスト構成

### 単体テスト (`tests/unit/`)
- Lambda関数の個別機能をテスト
- 外部サービスに依存しない高速なテスト
- 開発中の素早いフィードバック

### 結合テスト (`tests/integration/`)
- 実際のAWS環境での動作をテスト
- API Gateway + Lambda の連携確認
- 本番環境に近い条件でのテスト

**テスト例：**
```python
# 単体テスト例
def test_lambda_handler():
    # Lambda関数の戻り値をテスト
    response = lambda_handler(test_event, None)
    assert response['statusCode'] == 200

# 結合テスト例  
def test_api_gateway_integration():
    # 実際のAPIエンドポイントをテスト
    response = requests.get(api_url)
    assert response.status_code == 200
```

## 📖 学習の進め方

### 🔰 初心者向け

1. **まずは実行してみる**
   ```bash
   ./simple-test.sh
   ```

2. **コードを読んでみる**
   - `hello_world/app.py` - Lambda関数
   - `template.yaml` - AWSリソース定義
   - `tests/` - テストコード

3. **コードを変更してみる**
   - レスポンスメッセージを変更
   - 新しいテストケースを追加

### 🚀 中級者向け

- Lambda関数に新機能を追加
- DynamoDBなどの他のAWSサービスと連携
- CI/CDパイプラインの構築
- セキュリティの実装

## 🛠️ 便利なコマンド

```bash
# ログの確認
sam logs -n HelloWorldFunction --stack-name sam-sample-pytest --tail

# ローカルでAPIを起動してテスト
sam local start-api &
curl http://localhost:3000/hello

# テストカバレッジの詳細表示
pytest tests/unit/ --cov=hello_world --cov-report=html

# リソースの削除
sam delete --stack-name "sam-sample-pytest"
```

## 🌐 参考リンク

- **AWS SAM 公式ドキュメント**: [aws.amazon.com/serverless/sam](https://aws.amazon.com/serverless/sam/)
- **pytest 公式ドキュメント**: [docs.pytest.org](https://docs.pytest.org/)
- **AWS Lambda 開発者ガイド**: [docs.aws.amazon.com/lambda](https://docs.aws.amazon.com/lambda/)

## 🤝 貢献方法

このリポジトリは学習目的で作成されています。改善案やバグ報告があれば、以下の方法で貢献できます：

1. Issueを作成して問題や改善案を報告
2. Fork してプルリクエストを送信
3. 学習者向けのドキュメント改善

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。学習・改変・再配布は自由に行えます。

---

**🎓 学習を楽しんでください！** 

質問があれば、Issueで気軽に聞いてください。初心者の方も歓迎です！
