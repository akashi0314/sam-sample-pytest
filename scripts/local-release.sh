#!/bin/bash

# ==================================================================
# SAM (Serverless Application Model) 実行スクリプト集 - Git Bash用
# ==================================================================
# 
# このスクリプトは SAM アプリケーションの開発・デプロイを
# 段階的に実行するためのコマンド集です。
#
# 前提条件:
# - AWS CLI がインストール・設定済み
# - SAM CLI がインストール済み
# - Python 3.12 がインストール済み
# - Git Bash 環境
#
# 使用方法:
#   chmod +x sam_scripts.sh
#   ./sam_scripts.sh
#
# または個別コマンド実行:
#   ./sam_scripts.sh check_env
#   ./sam_scripts.sh local_test
#   ./sam_scripts.sh deploy
# ==================================================================

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ロギング関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==================================================================
# 1. 環境確認 - 必要なツールがインストールされているかチェック
# ==================================================================
check_environment() {
    echo
    echo "========================================"
    log_info "環境確認を実行中..."
    echo "========================================"
    
    local all_ok=true
    
    # AWS CLI の確認
    log_info "[1/5] AWS CLI の確認..."
    if command -v aws &> /dev/null; then
        aws --version
        log_success "AWS CLI が利用可能です"
    else
        log_error "AWS CLI がインストールされていません"
        log_error "https://aws.amazon.com/cli/ からインストールしてください"
        all_ok=false
    fi
    
    # SAM CLI の確認
    log_info "[2/5] SAM CLI の確認..."
    if command -v sam &> /dev/null; then
        sam --version
        log_success "SAM CLI が利用可能です"
    else
        log_error "SAM CLI がインストールされていません"
        log_error "https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
        all_ok=false
    fi
    
    # Python の確認
    log_info "[3/5] Python の確認..."
    if command -v python &> /dev/null; then
        python --version
        log_success "Python が利用可能です"
    else
        log_error "Python がインストールされていません"
        all_ok=false
    fi
    
    # Docker の確認（SAM Local用）
    log_info "[4/5] Docker の確認..."
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        docker --version
        log_success "Docker が利用可能です"
    else
        log_warning "Docker が利用できません（SAM Localの実行には必要）"
        log_warning "https://www.docker.com/get-started からインストールしてください"
    fi
    
    # AWS認証情報の確認
    log_info "[5/5] AWS認証情報の確認..."
    if aws sts get-caller-identity &> /dev/null; then
        aws sts get-caller-identity --query '[Account,UserId,Arn]' --output table
        log_success "AWS認証情報が設定されています"
    else
        log_error "AWS認証情報が設定されていません"
        log_error "aws configure を実行して設定してください"
        all_ok=false
    fi
    
    echo
    if [ "$all_ok" = true ]; then
        log_success "環境確認完了: すべての要件が満たされています"
        return 0
    else
        log_error "環境確認失敗: 不足している要件があります"
        return 1
    fi
}

# ==================================================================
# 2. 依存関係のインストール
# ==================================================================
install_dependencies() {
    echo
    echo "========================================"
    log_info "依存関係のインストール..."
    echo "========================================"
    
    log_info "Python依存関係をインストール中..."
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        log_success "requirements.txt からの依存関係インストール完了"
    fi
    
    if [ -f "requirements-dev.txt" ]; then
        pip install -r requirements-dev.txt
        log_success "requirements-dev.txt からの依存関係インストール完了"
    fi
    
    # pytestが利用可能か確認
    if command -v pytest &> /dev/null; then
        log_success "pytest が利用可能です"
    else
        log_info "pytest をインストール中..."
        pip install pytest pytest-cov
    fi
}

# ==================================================================
# 3. ローカル単体テスト実行
# ==================================================================
run_unit_tests() {
    echo
    echo "========================================"
    log_info "単体テスト実行中..."
    echo "========================================"
    
    if [ -d "tests/unit" ]; then
        log_info "単体テストを実行します..."
        pytest tests/unit/ -v
        if [ $? -eq 0 ]; then
            log_success "単体テスト完了"
        else
            log_error "単体テストに失敗しました"
            return 1
        fi
    else
        log_warning "tests/unit ディレクトリが見つかりません"
    fi
}

# ==================================================================
# 4. SAM ビルド実行
# ==================================================================
sam_build() {
    echo
    echo "========================================"
    log_info "SAM ビルド実行中..."
    echo "========================================"
    
    # template.yaml の存在確認
    if [ ! -f "template.yaml" ]; then
        log_error "template.yaml が見つかりません"
        return 1
    fi
    
    log_info "SAM アプリケーションをビルド中..."
    sam build
    
    if [ $? -eq 0 ]; then
        log_success "SAM ビルド完了"
        
        # ビルド結果の確認
        if [ -d ".aws-sam" ]; then
            log_info "ビルド成果物:"
            ls -la .aws-sam/build/
        fi
    else
        log_error "SAM ビルドに失敗しました"
        return 1
    fi
}

# ==================================================================
# 5. ローカルでのLambda関数テスト
# ==================================================================
test_local_function() {
    echo
    echo "========================================"
    log_info "ローカル Lambda 関数テスト..."
    echo "========================================"
    
    # イベントファイルの確認
    local event_file="events/event.json"
    if [ ! -f "$event_file" ]; then
        log_warning "$event_file が見つかりません。デフォルトイベントファイルを作成します..."
        mkdir -p events
        cat > "$event_file" << 'EOF'
{
  "httpMethod": "GET",
  "path": "/hello",
  "headers": {},
  "queryStringParameters": null,
  "body": null
}
EOF
        log_info "デフォルトイベントファイルを作成しました: $event_file"
    fi
    
    log_info "Lambda関数をローカルで実行中..."
    sam local invoke HelloWorldFunction --event "$event_file"
    
    if [ $? -eq 0 ]; then
        log_success "ローカル Lambda 関数テスト完了"
    else
        log_error "ローカル Lambda 関数テストに失敗しました"
        return 1
    fi
}

# ==================================================================
# 6. ローカルAPIサーバー起動
# ==================================================================
start_local_api() {
    echo
    echo "========================================"
    log_info "ローカル API サーバー起動..."
    echo "========================================"
    
    log_info "ローカル API Gateway を起動します..."
    log_info "起動後、ブラウザで http://localhost:3000/hello にアクセスしてテストできます"
    log_info "停止するには Ctrl+C を押してください"
    echo
    
    # バックグラウンドで起動する場合のオプション
    read -p "バックグラウンドで起動しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sam local start-api --host 0.0.0.0 --port 3000 &
        local pid=$!
        log_info "ローカル API サーバーがバックグラウンドで起動しました (PID: $pid)"
        log_info "停止するには: kill $pid"
        
        # 少し待ってからテスト
        sleep 3
        log_info "API テスト実行中..."
        curl -s http://localhost:3000/hello | jq . || echo "レスポンス確認完了"
    else
        sam local start-api --host 0.0.0.0 --port 3000
    fi
}

# ==================================================================
# 7. AWS へのデプロイ
# ==================================================================
deploy_to_aws() {
    echo
    echo "========================================"
    log_info "AWS へのデプロイ..."
    echo "========================================"
    
    # スタック名の確認
    local stack_name="sam-sample-pytest"
    read -p "スタック名を入力してください [$stack_name]: " input_stack_name
    stack_name=${input_stack_name:-$stack_name}
    
    log_info "スタック名: $stack_name"
    
    # 初回デプロイかどうかの確認
    log_info "既存スタックの確認中..."
    if aws cloudformation describe-stacks --stack-name "$stack_name" &> /dev/null; then
        log_info "既存スタック '$stack_name' が見つかりました。更新を実行します..."
        sam deploy --stack-name "$stack_name"
    else
        log_info "新規スタックとしてデプロイします..."
        sam deploy --guided --stack-name "$stack_name"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "デプロイ完了"
        
        # スタック出力の表示
        log_info "スタック出力:"
        aws cloudformation describe-stacks \
            --stack-name "$stack_name" \
            --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
            --output table
            
        # API URL の取得とテスト
        local api_url=$(aws cloudformation describe-stacks \
            --stack-name "$stack_name" \
            --query 'Stacks[0].Outputs[?OutputKey==`HelloWorldApi`].OutputValue' \
            --output text)
            
        if [ ! -z "$api_url" ]; then
            log_info "デプロイされたAPIをテスト中..."
            echo "URL: $api_url"
            curl -s "$api_url" | jq . || echo "API テスト完了"
        fi
        
    else
        log_error "デプロイに失敗しました"
        return 1
    fi
}

# ==================================================================
# 8. 結合テスト実行（オプション）
# ==================================================================
run_integration_tests() {
    echo
    echo "========================================"
    log_info "結合テスト実行（オプション）..."
    echo "========================================"
    
    # スタック名の確認
    local stack_name="sam-sample-pytest"
    read -p "テスト対象のスタック名を入力してください [$stack_name]: " input_stack_name
    stack_name=${input_stack_name:-$stack_name}
    
    if [ -d "tests/integration" ]; then
        log_info "結合テストを実行します..."
        export AWS_SAM_STACK_NAME="$stack_name"
        pytest tests/integration/ -v -m "not slow"
        
        if [ $? -eq 0 ]; then
            log_success "結合テスト完了"
        else
            log_error "結合テストに失敗しました"
            return 1
        fi
    else
        log_warning "tests/integration ディレクトリが見つかりません"
    fi
}

# ==================================================================
# 9. クリーンアップ
# ==================================================================
cleanup() {
    echo
    echo "========================================"
    log_info "クリーンアップ..."
    echo "========================================"
    
    read -p "スタックを削除しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local stack_name="sam-sample-pytest"
        read -p "削除するスタック名を入力してください [$stack_name]: " input_stack_name
        stack_name=${input_stack_name:-$stack_name}
        
        log_warning "スタック '$stack_name' を削除します..."
        aws cloudformation delete-stack --stack-name "$stack_name"
        
        log_info "削除処理を開始しました。完了まで数分かかります..."
        aws cloudformation wait stack-delete-complete --stack-name "$stack_name"
        
        if [ $? -eq 0 ]; then
            log_success "スタック削除完了"
        else
            log_error "スタック削除に失敗しました"
        fi
    fi
    
    # ローカルファイルのクリーンアップ
    read -p "ローカルビルドファイルを削除しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf .aws-sam/
        log_success "ローカルビルドファイルを削除しました"
    fi
}

# ==================================================================
# 10. 全体の実行フロー
# ==================================================================
run_full_workflow() {
    echo
    echo "========================================"
    log_info "SAM 全体ワークフロー実行..."
    echo "========================================"
    
    # 1. 環境確認
    check_environment || return 1
    
    # 2. 依存関係インストール
    install_dependencies || return 1
    
    # 3. 単体テスト
    run_unit_tests || return 1
    
    # 4. ビルド
    sam_build || return 1
    
    # 5. ローカルテスト
    test_local_function || return 1
    
    # 6. デプロイ確認
    read -p "AWS にデプロイしますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_to_aws || return 1
        
        # 7. 結合テスト
        read -p "結合テストを実行しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_integration_tests
        fi
    fi
    
    log_success "ワークフロー完了！"
}

# ==================================================================
# ヘルプ表示
# ==================================================================
show_help() {
    echo "SAM 実行スクリプト - 使用方法"
    echo
    echo "使用方法:"
    echo "  $0 [コマンド]"
    echo
    echo "利用可能なコマンド:"
    echo "  check_env          - 環境確認"
    echo "  install_deps       - 依存関係インストール"
    echo "  unit_test          - 単体テスト実行"
    echo "  build              - SAM ビルド"
    echo "  test_local         - ローカル Lambda テスト"
    echo "  start_api          - ローカル API サーバー起動"
    echo "  deploy             - AWS デプロイ"
    echo "  integration_test   - 結合テスト実行"
    echo "  cleanup            - クリーンアップ"
    echo "  full               - 全体ワークフロー実行"
    echo "  help               - このヘルプを表示"
    echo
    echo "例:"
    echo "  $0 check_env       # 環境確認のみ"
    echo "  $0 full            # 全体フロー実行"
    echo "  $0 build && $0 test_local  # ビルド後にローカルテスト"
}

# ==================================================================
# メイン処理
# ==================================================================
main() {
    case "${1:-help}" in
        "check_env"|"check")
            check_environment
            ;;
        "install_deps"|"install")
            install_dependencies
            ;;
        "unit_test"|"unit")
            run_unit_tests
            ;;
        "build")
            sam_build
            ;;
        "test_local"|"local")
            test_local_function
            ;;
        "start_api"|"api")
            start_local_api
            ;;
        "deploy")
            deploy_to_aws
            ;;
        "integration_test"|"integration")
            run_integration_tests
            ;;
        "cleanup"|"clean")
            cleanup
            ;;
        "full"|"all")
            run_full_workflow
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "不明なコマンド: $1"
            show_help
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"