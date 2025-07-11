#!/bin/bash
# =============================================================================
# AWS SAM 自動テスト学習スクリプト
# 初心者がAWSサーバーレス開発とテストを学ぶためのスクリプト
# 
# 📚 このスクリプトで学べること:
#   - AWS SAMの基本的な使い方
#   - Pythonのテスト手法 (pytest)
#   - ローカル開発とクラウドデプロイ
#   - 自動テストの重要性
#
# 🚀 使い方:
#   ./simple-test.sh           # 全部のステップを実行
#   ./simple-test.sh setup     # 環境の準備だけ
#   ./simple-test.sh build     # プログラムの構築とテスト
#   ./simple-test.sh local     # 自分のパソコンでテスト
#   ./simple-test.sh deploy    # AWSにアップロードしてテスト
#   ./simple-test.sh help      # 使い方を表示
# =============================================================================

set -e

# 基本設定
AWS_REGION="us-east-1"          # AWSのリージョン（どこのサーバーを使うか）
STACK_NAME="sam-sample-pytest"  # アプリケーションの名前

# 表示色の設定（見やすくするため）
GREEN='\033[0;32m'   # 成功時の緑色
BLUE='\033[0;34m'    # 情報表示の青色
YELLOW='\033[1;33m'  # 警告の黄色
RED='\033[0;31m'     # エラーの赤色
NC='\033[0m'         # 色をリセット

# 表示用の関数（きれいに表示するため）
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_step() {
    echo -e "${GREEN}🚀 ステップ: $1${NC}"
    echo -e "${GREEN}$(printf '=%.0s' {1..50})${NC}"
}

print_success() {
    echo -e "${GREEN}✅ 成功: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  注意: $1${NC}"
}

print_error() {
    echo -e "${RED}❌ エラー: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  情報: $1${NC}"
}

# =============================================================================
# ステップ1: 開発環境の準備
# =============================================================================
setup_environment() {
    print_step "開発環境の準備"
    echo ""
    echo "📖 このステップで学ぶこと: 開発に必要なツールが揃っているかチェック"
    echo ""

    # Pythonがインストールされているかチェック
    print_info "Pythonが使えるかチェック中..."
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        print_success "Python見つかりました: $PYTHON_VERSION"
    else
        print_error "Python3がありません"
        echo "💡 解決方法: https://www.python.org/ からPython3をダウンロードしてください"
        return 1
    fi

    # AWS CLIがインストールされているかチェック
    print_info "AWS CLI（AWSを操作するツール）をチェック中..."
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        print_success "AWS CLI見つかりました: $AWS_VERSION"
    else
        print_error "AWS CLIがありません"
        echo "💡 解決方法: https://aws.amazon.com/cli/ からAWS CLIをインストールしてください"
        return 1
    fi

    # SAM CLIがインストールされているかチェック
    print_info "SAM CLI（サーバーレス開発ツール）をチェック中..."
    if command -v sam &> /dev/null; then
        SAM_VERSION=$(sam --version 2>&1)
        print_success "SAM CLI見つかりました: $SAM_VERSION"
    else
        print_error "SAM CLIがありません"
        echo "💡 解決方法: SAM CLIをインストールしてください"
        echo "   詳細: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
        return 1
    fi

    # 必要なPythonライブラリをインストール
    print_info "必要なPythonライブラリをインストール中..."
    echo "📦 インストールするもの:"
    echo "   - pytest: テストを実行するツール"
    echo "   - pytest-cov: テストのカバレッジ（どこまでテストしたか）を測るツール"
    echo "   - boto3: PythonでAWSを操作するライブラリ"
    echo "   - requests: HTTPリクエストを送るライブラリ"
    
    if pip install pytest pytest-cov boto3 requests; then
        print_success "ライブラリのインストール完了"
    else
        print_error "ライブラリのインストールに失敗"
        echo "💡 解決方法: pipが正しくインストールされているか確認してください"
        return 1
    fi

    # AWSの認証設定をチェック
    print_info "AWSにアクセスできるかチェック中..."
    if aws sts get-caller-identity --region $AWS_REGION &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --region $AWS_REGION --query 'Account' --output text)
        print_success "AWS接続成功 (アカウント: $ACCOUNT_ID)"
    else
        print_warning "AWS認証の設定が必要です"
        echo "💡 解決方法: 'aws configure' コマンドで以下を設定してください:"
        echo "   - AWS Access Key ID"
        echo "   - AWS Secret Access Key"
        echo "   - Default region name: $AWS_REGION"
        echo "   - Default output format: json"
    fi

    print_success "環境準備が完了しました！"
    echo ""
}

# =============================================================================
# ステップ2: プログラムの構築とテスト
# =============================================================================
build_and_unit_test() {
    print_step "プログラムの構築とテスト"
    echo ""
    echo "📖 このステップで学ぶこと: プログラムをビルドして、個別の機能をテストする"
    echo ""

    # プロジェクトの構造をチェック
    print_info "プロジェクトファイルの存在チェック中..."
    
    if [ ! -f "template.yaml" ]; then
        print_error "template.yaml が見つかりません"
        echo "💡 解決方法: SAMプロジェクトのルートフォルダで実行してください"
        return 1
    fi

    if [ ! -d "hello_world" ]; then
        print_error "hello_world フォルダが見つかりません"
        echo "💡 解決方法: プロジェクトが正しく作成されているか確認してください"
        return 1
    fi

    if [ ! -d "tests/unit" ]; then
        print_error "tests/unit フォルダが見つかりません"
        echo "💡 解決方法: テストフォルダが存在するか確認してください"
        return 1
    fi

    print_success "プロジェクト構造OK"

    # SAM Buildを実行
    print_info "SAM Build を実行中..."
    echo "🔧 SAM Build の役割:"
    echo "   - Lambda関数に必要なライブラリを集める"
    echo "   - AWSにアップロードできる形にパッケージ化"
    echo "   - .aws-sam/build/ フォルダに結果を保存"
    echo ""

    if sam build; then
        print_success "SAM Build 完了"
    else
        print_error "SAM Build でエラーが発生しました"
        echo "💡 解決方法: template.yamlや requirements.txt の設定を確認してください"
        return 1
    fi

    # 単体テストを実行
    print_info "単体テスト（ユニットテスト）を実行中..."
    echo "🧪 単体テストとは:"
    echo "   - プログラムの小さな部分を個別にテスト"
    echo "   - バグを早期発見できる"
    echo "   - コードの品質を保つ"
    echo ""

    if pytest tests/unit/ -v; then
        print_success "単体テスト完了 - 全てのテストがパス！"
    else
        print_error "単体テストで失敗したテストがあります"
        echo "💡 解決方法: テストの詳細を確認して、コードを修正してください"
        return 1
    fi

    # テストカバレッジを測定（オプション）
    print_info "テストカバレッジを測定中..."
    echo "📊 カバレッジとは: コードのどの部分がテストされたかの割合"
    
    if pytest tests/unit/ --cov=hello_world --cov-report=term 2>/dev/null; then
        print_success "カバレッジ測定完了"
        echo "💡 カバレッジが低い場合は、テストを追加することを検討してください"
    else
        print_warning "カバレッジ測定をスキップ（pytest-covが必要）"
    fi

    print_success "プログラムの構築とテストが完了しました！"
    echo ""
}

# =============================================================================
# ステップ3: 自分のパソコンでテスト
# =============================================================================
local_test() {
    print_step "ローカルテスト（自分のパソコンでテスト）"
    echo ""
    echo "📖 このステップで学ぶこと: AWSにアップロードする前に、自分のパソコンで動作確認"
    echo ""

    # ビルド済みファイルがあるかチェック
    if [ ! -d ".aws-sam/build" ]; then
        print_error "ビルド済みファイルが見つかりません"
        echo "💡 解決方法: 先に 'build' ステップを実行してください"
        return 1
    fi

    # Dockerが動いているかチェック
    print_info "Docker（仮想環境ツール）をチェック中..."
    if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        print_success "Docker利用可能"
    else
        print_warning "Dockerが使えません"
        echo "💡 解決方法:"
        echo "   1. Docker Desktop をインストール"
        echo "   2. Docker Desktop を起動"
        echo "   3. Docker が正常に動作していることを確認"
        echo ""
        echo "🔄 ローカルテストをスキップして続行します"
        return 0
    fi

    # テスト用のイベントファイルを準備
    print_info "テスト用データの準備中..."
    EVENT_DIR="events"
    EVENT_FILE="$EVENT_DIR/event.json"

    mkdir -p "$EVENT_DIR"

    if [ ! -f "$EVENT_FILE" ]; then
        print_info "サンプルリクエストデータを作成中..."
        cat > "$EVENT_FILE" << 'EOF'
{
  "httpMethod": "GET",
  "path": "/hello",
  "pathParameters": null,
  "queryStringParameters": null,
  "headers": {
    "Accept": "application/json",
    "User-Agent": "local-test"
  },
  "body": null,
  "isBase64Encoded": false,
  "requestContext": {
    "httpMethod": "GET",
    "requestId": "test-request-123",
    "stage": "test"
  }
}
EOF
        print_success "テストデータ ($EVENT_FILE) を作成しました"
    fi

    # sam local invoke を実行
    print_info "Lambda関数を自分のパソコンで実行中..."
    echo "🏠 ローカル実行の利点:"
    echo "   - AWSにアップロードせずにテストできる"
    echo "   - 開発中の素早い動作確認"
    echo "   - 本番環境に近い条件でのテスト"
    echo ""
    echo "実行コマンド: sam local invoke HelloWorldFunction --event $EVENT_FILE"
    echo ""

    if sam local invoke HelloWorldFunction --event "$EVENT_FILE"; then
        echo ""
        print_success "ローカル実行成功！Lambda関数が正常に動作しました"
    else
        print_error "ローカル実行でエラーが発生しました"
        echo "💡 解決方法:"
        echo "   - Dockerが正常に動作しているか確認"
        echo "   - Lambda関数のコードにエラーがないか確認"
        return 1
    fi

    print_success "ローカルテストが完了しました！"
    echo ""
}

# =============================================================================
# ステップ4: AWSにアップロードしてテスト
# =============================================================================
deploy_and_integration_test() {
    print_step "AWSクラウドにデプロイして結合テスト"
    echo ""
    echo "📖 このステップで学ぶこと: 実際のAWS環境でアプリケーション全体をテスト"
    echo ""

    # ビルド済みファイルがあるかチェック
    if [ ! -d ".aws-sam/build" ]; then
        print_error "ビルド済みファイルが見つかりません"
        echo "💡 解決方法: 先に 'build' ステップを実行してください"
        return 1
    fi

    # AWS認証をチェック
    print_info "AWS接続をチェック中..."
    if aws sts get-caller-identity --region $AWS_REGION &> /dev/null; then
        print_success "AWS接続OK"
    else
        print_error "AWSに接続できません"
        echo "💡 解決方法: 'aws configure' でアクセスキーを設定してください"
        return 1
    fi

    # 既存のスタックをチェック
    print_info "既存のアプリケーションをチェック中..."
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION &> /dev/null; then
        STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text)
        print_info "アプリケーション '$STACK_NAME' が既に存在します (状態: $STACK_STATUS)"
    else
        print_info "新しいアプリケーション '$STACK_NAME' を作成します"
    fi

    # SAM Deploy を実行
    print_info "AWS クラウドにアップロード中..."
    echo "☁️ デプロイの役割:"
    echo "   - CloudFormation でAWSリソースを自動作成"
    echo "   - API Gateway（Webエンドポイント）を作成"
    echo "   - Lambda関数をアップロード"
    echo "   - 必要な権限（IAMロール）を設定"
    echo ""

    if [ -f "samconfig.toml" ]; then
        print_info "保存済み設定でデプロイ実行"
        
        # sam deploy の結果をチェック
        if sam_output=$(sam deploy 2>&1); then
            print_success "デプロイ完了"
        else
            # 変更がない場合の処理
            if echo "$sam_output" | grep -q "No changes to deploy"; then
                print_success "デプロイ済み（変更なし）"
                echo "アプリケーションは既に最新の状態です"
            else
                print_error "デプロイでエラーが発生しました"
                echo "$sam_output"
                echo "💡 解決方法: エラーメッセージを確認して、設定を見直してください"
                return 1
            fi
        fi
    else
        print_info "初回デプロイ（設定を行います）"
        echo "⚠️  いくつか質問されます。以下の設定をお勧めします:"
        echo "   📝 Stack Name: $STACK_NAME"
        echo "   🌍 AWS Region: $AWS_REGION"
        echo "   📤 その他の項目: Enter（デフォルト）でOK"
        echo ""
        
        if sam deploy --guided; then
            print_success "初回デプロイ完了"
        else
            print_error "デプロイでエラーが発生しました"
            echo "💡 解決方法: AWS認証情報と権限を確認してください"
            return 1
        fi
    fi

    # デプロイ完了を待機
    print_info "デプロイ完了を待機中..."
    sleep 10

    # API Gateway の URL を取得
    print_info "WebAPIのURLを取得中..."
    if API_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query 'Stacks[0].Outputs[?OutputKey==`HelloWorldApi`].OutputValue' --output text 2>/dev/null); then
        print_success "WebAPI URL: $API_URL"
    else
        print_error "WebAPI URLの取得に失敗しました"
        echo "💡 解決方法: CloudFormationスタックの出力を確認してください"
        return 1
    fi

    # 手動でAPIをテスト
    print_info "WebAPIの動作テスト中..."
    echo "🌐 curl コマンドでAPIエンドポイントをテスト..."
    echo ""
    
    if curl -s "$API_URL" | python -m json.tool 2>/dev/null; then
        echo ""
        print_success "手動テスト成功 - APIが正常に応答しました！"
    else
        echo ""
        print_warning "手動テストで問題発生（APIの起動中の可能性があります）"
        echo "💡 数分待ってから再度テストしてみてください"
    fi

    # 結合テストを実行
    print_info "結合テスト（全体テスト）を実行中..."
    echo "🔗 結合テストとは:"
    echo "   - 実際のAWS環境で全体の動作を確認"
    echo "   - API Gateway → Lambda の連携をテスト"
    echo "   - 本番環境と同じ条件でのテスト"
    echo ""

    if [ ! -d "tests/integration" ]; then
        print_error "tests/integration フォルダが見つかりません"
        echo "💡 解決方法: 結合テスト用のフォルダとファイルを作成してください"
        return 1
    fi

    # 環境変数を設定してテスト実行
    export AWS_DEFAULT_REGION=$AWS_REGION
    export AWS_SAM_STACK_NAME=$STACK_NAME

    if pytest tests/integration/ -v; then
        print_success "結合テスト完了 - 全てのテストがパス！"
        echo ""
        print_success "🎉 すべてのテストが完了しました！"
        echo ""
        print_info "🌐 デプロイされたWebAPI: $API_URL"
        echo "💡 ブラウザでアクセスして動作を確認できます"
    else
        print_error "結合テストで失敗したテストがあります"
        echo "💡 解決方法: テストの詳細を確認して、問題を修正してください"
        return 1
    fi

    print_success "デプロイと結合テストが完了しました！"
    echo ""
}

# =============================================================================
# ヘルプ表示
# =============================================================================
show_help() {
    print_header "AWS SAM 自動テスト学習スクリプト"
    echo ""
    echo "🎓 初心者がAWSサーバーレス開発を学ぶためのスクリプトです"
    echo ""
    echo "📚 このスクリプトで学べること:"
    echo "  1. 🛠️  環境準備 - 必要なツールの確認とセットアップ"
    echo "  2. 🏗️  ビルド+単体テスト - プログラムの構築と個別機能のテスト"
    echo "  3. 🏠 ローカルテスト - 自分のパソコンでの動作確認"
    echo "  4. ☁️  デプロイ+結合テスト - AWSクラウドでの全体テスト"
    echo ""
    echo "🚀 使い方:"
    echo "  ./simple-test.sh           # 全ステップを順番に実行（推奨）"
    echo "  ./simple-test.sh setup     # 環境準備だけ実行"
    echo "  ./simple-test.sh build     # ビルド+単体テストだけ実行"
    echo "  ./simple-test.sh local     # ローカルテストだけ実行"
    echo "  ./simple-test.sh deploy    # デプロイ+結合テストだけ実行"
    echo "  ./simple-test.sh help      # このヘルプを表示"
    echo ""
    echo "⚙️ 現在の設定:"
    echo "  🌍 AWS Region: $AWS_REGION"
    echo "  📦 Stack Name: $STACK_NAME"
    echo ""
    echo "💡 初めての方へ:"
    echo "  最初は全ステップを順番に実行することをお勧めします"
    echo "  各ステップで何を学んでいるかに注目してください"
    echo ""
    echo "📞 困ったときは:"
    echo "  エラーメッセージの「💡 解決方法」を参考にしてください"
    echo ""
}

# =============================================================================
# メイン処理
# =============================================================================
main() {
    local command=${1:-all}
    
    case $command in
        "setup")
            print_header "AWS SAM学習 - 環境準備"
            setup_environment
            ;;
        "build")
            print_header "AWS SAM学習 - プログラム構築とテスト"
            build_and_unit_test
            ;;
        "local")
            print_header "AWS SAM学習 - ローカルテスト"
            local_test
            ;;
        "deploy")
            print_header "AWS SAM学習 - クラウドデプロイとテスト"
            deploy_and_integration_test
            ;;
        "all")
            print_header "AWS SAM学習 - 完全ワークフロー"
            echo ""
            echo "🎓 全ステップを順番に実行します："
            echo "   1. 🛠️  環境準備"
            echo "   2. 🏗️  プログラム構築とテスト"
            echo "   3. 🏠 ローカルテスト"
            echo "   4. ☁️  クラウドデプロイとテスト"
            echo ""
            echo "⏱️  予想実行時間: 約5-10分"
            echo "💡 各ステップで何を学んでいるかに注目してください"
            echo ""
            
            setup_environment && \
            build_and_unit_test && \
            local_test && \
            deploy_and_integration_test
            
            if [ $? -eq 0 ]; then
                echo ""
                print_header "🎉 学習コンプリート！"
                echo ""
                echo "🏆 習得したスキル："
                echo "   ✅ AWS SAM の基本操作"
                echo "   ✅ pytest による自動テスト"
                echo "   ✅ ローカル開発環境の活用"
                echo "   ✅ AWS クラウドへのデプロイ"
                echo "   ✅ エンドツーエンドテスト"
                echo ""
                echo "🚀 次のチャレンジ："
                echo "   🔹 CI/CDパイプラインの学習"
                echo "   🔹 より複雑なアプリケーション開発"
                echo "   🔹 本番運用のベストプラクティス"
                echo "   🔹 セキュリティの実装"
                echo ""
            else
                print_error "学習中に問題が発生しました"
                echo "💡 エラーメッセージを確認して、問題を解決してから再実行してください"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "不明なコマンド: $command"
            echo "💡 正しいコマンドを確認するには、以下を実行してください:"
            echo "   ./simple-test.sh help"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"