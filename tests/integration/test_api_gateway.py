# tests/integration/test_api_gateway_simple.py
"""
シンプルなAPI Gateway結合テスト
学習者向けの最小限のテストセット
"""
import os
import time
import boto3
import pytest
import requests
from botocore.exceptions import ClientError


class TestApiGatewaySimple:
    """
    シンプルなAPI Gateway結合テスト
    
    目的：
    - API Gateway + Lambda の基本動作確認
    - 学習者向けの理解しやすいテスト
    - 最小限のテストで最大の価値を提供
    """
    
    @pytest.fixture(scope="class")
    def api_gateway_url(self):
        """CloudFormation Stack から API Gateway URL を取得"""
        stack_name = os.environ.get("AWS_SAM_STACK_NAME")
        if stack_name is None:
            pytest.skip("AWS_SAM_STACK_NAME environment variable not set")
        
        client = boto3.client("cloudformation")
        try:
            response = client.describe_stacks(StackName=stack_name)
        except ClientError as e:
            if e.response['Error']['Code'] == 'ValidationError':
                pytest.skip(f"Stack {stack_name} does not exist")
            raise
        
        stacks = response["Stacks"]
        stack_outputs = stacks[0]["Outputs"]
        api_outputs = [output for output in stack_outputs 
                      if output["OutputKey"] == "HelloWorldApi"]
        if not api_outputs:
            pytest.skip(f"HelloWorldApi output not found in stack {stack_name}")
        return api_outputs[0]["OutputValue"]
    
    def test_api_gateway_basic_functionality(self, api_gateway_url):
        """
        テスト1: 基本的なエンドツーエンドテスト
        
        確認内容：
        - HTTP 200が返る
        - JSONレスポンスが返る
        - 期待するメッセージが含まれる
        """
        print(f"Testing URL: {api_gateway_url}")
        
        response = requests.get(api_gateway_url, timeout=10)
        
        # ステータスコード確認
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        # Content-Type確認
        content_type = response.headers.get('content-type', '')
        assert "application/json" in content_type, f"Expected JSON, got {content_type}"
        
        # レスポンス内容確認
        json_response = response.json()
        assert "message" in json_response, "Response should contain 'message' field"
        assert json_response["message"] == "hello world", f"Expected 'hello world', got {json_response['message']}"
        
        print("✅ Basic functionality test passed")
    
    def test_api_gateway_response_time(self, api_gateway_url):
        """
        テスト2: レスポンス時間の確認
        
        確認内容：
        - 5秒以内にレスポンスが返る
        - 実際の環境での性能確認
        """
        start_time = time.time()
        response = requests.get(api_gateway_url, timeout=10)
        end_time = time.time()
        
        response_time = end_time - start_time
        
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert response_time < 5.0, f"Response time too slow: {response_time:.2f}s (should be < 5.0s)"
        
        print(f"✅ Response time test passed: {response_time:.2f}s")
    
    def test_api_gateway_consistency(self, api_gateway_url):
        """
        テスト3: レスポンスの一貫性確認
        
        確認内容：
        - 複数回リクエストしても同じ結果が返る
        - 冪等性の確認
        """
        responses = []
        
        # 3回リクエスト実行
        for i in range(3):
            response = requests.get(api_gateway_url, timeout=10)
            assert response.status_code == 200, f"Request {i+1} failed with {response.status_code}"
            responses.append(response.json())
        
        # 全て同じレスポンスであることを確認
        first_response = responses[0]
        for i, response in enumerate(responses[1:], 2):
            assert response == first_response, f"Request {i} returned different response"
        
        print("✅ Consistency test passed: All responses identical")
    
    def test_cloudformation_integration(self):
        """
        テスト4: CloudFormationスタック統合確認
        
        確認内容：
        - スタックが正常にデプロイされている
        - 必要な出力値が存在する
        - API Gateway URLが正しい形式
        """
        stack_name = os.environ.get("AWS_SAM_STACK_NAME")
        if stack_name is None:
            pytest.skip("AWS_SAM_STACK_NAME environment variable not set")
        
        client = boto3.client("cloudformation")
        response = client.describe_stacks(StackName=stack_name)
        
        stack = response["Stacks"][0]
        
        # スタック状態確認
        assert stack["StackStatus"] == "CREATE_COMPLETE", f"Stack status: {stack['StackStatus']}"
        
        # 出力値の確認
        outputs = stack.get("Outputs", [])
        assert len(outputs) > 0, "Stack should have outputs"
        
        # HelloWorldApi出力の確認
        api_outputs = [output for output in outputs 
                      if output["OutputKey"] == "HelloWorldApi"]
        assert len(api_outputs) == 1, "HelloWorldApi output not found"
        
        api_url = api_outputs[0]["OutputValue"]
        assert api_url.startswith("https://"), f"API URL should be HTTPS: {api_url}"
        assert "execute-api" in api_url, f"Should be API Gateway URL: {api_url}"
        
        print(f"✅ CloudFormation integration test passed: {api_url}")


# 実行方法:
# 1. AWS SAMアプリケーションをデプロイ:
#    sam build && sam deploy --guided
#
# 2. 環境変数を設定してテスト実行:
#    AWS_SAM_STACK_NAME="your-stack-name" pytest tests/integration/test_api_gateway_simple.py -v
#
# 3. 詳細な出力を見たい場合:
#    AWS_SAM_STACK_NAME="your-stack-name" pytest tests/integration/test_api_gateway_simple.py -v -s