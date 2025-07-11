import json
import pytest
from unittest.mock import Mock

from hello_world import app


@pytest.fixture
def apigw_event():
    """API Gateway Lambda Proxy Input Format のモックデータを生成"""
    return {
        "body": '{"test": "body"}',
        "resource": "/{proxy+}",
        "requestContext": {
            "resourceId": "123456",
            "apiId": "1234567890",
            "resourcePath": "/{proxy+}",
            "httpMethod": "GET",
            "requestId": "c6af9ac6-7b61-11e6-9a41-93e8deadbeef",
            "protocol": "HTTP/1.1",
            "stage": "test"
        },
        "queryStringParameters": {"foo": "bar"},
        "headers": {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Encoding": "gzip, deflate, sdch",
            "Accept-Language": "en-US,en;q=0.8",
            "Cache-Control": "max-age=0",
            "CloudFront-Forwarded-Proto": "https",
            "CloudFront-Is-Desktop-Viewer": "true",
            "CloudFront-Is-Mobile-Viewer": "false",
            "CloudFront-Is-SmartTV-Viewer": "false",
            "CloudFront-Is-Tablet-Viewer": "false",
            "CloudFront-Viewer-Country": "US",
            "Host": "1234567890.execute-api.us-east-1.amazonaws.com",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": "Custom User Agent String",
            "Via": "1.1 08f323deadbeefa7af34d5feb414ce27.cloudfront.net (CloudFront)",
            "X-Amz-Cf-Id": "cDehVQoZnx43VYQb9j2-nvCh-9z396Uhbp027Y2JvkCPNLmGJHqlaA==",
            "X-Forwarded-For": "127.0.0.1, 127.0.0.2",
            "X-Forwarded-Port": "443",
            "X-Forwarded-Proto": "https"
        },
        "pathParameters": {"proxy": "/examplepath"},
        "httpMethod": "GET",
        "stageVariables": {"baz": "qux"},
        "path": "/examplepath"
    }


@pytest.fixture
def lambda_context():
    """Lambda Context runtime methods and attributes のモック"""
    context = Mock()
    context.function_name = "test-function"
    context.function_version = "$LATEST"
    context.invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test-function"
    context.memory_limit_in_mb = 128
    context.remaining_time_in_millis = lambda: 30000
    return context


class TestLambdaHandlerBasicFunctionality:
    """基本機能テスト"""
    
    def test_lambda_handler_returns_200_status(self, apigw_event, lambda_context):
        """BF-01: 常にHTTPステータスコード200を返すことを確認"""
        # 実行
        response = app.lambda_handler(apigw_event, lambda_context)
        
        # 検証
        assert response["statusCode"] == 200
        assert isinstance(response["statusCode"], int)
        assert 200 <= response["statusCode"] < 600
    
    def test_lambda_handler_returns_hello_world_message(self, apigw_event, lambda_context):
        """BF-02: 固定メッセージ"hello world"を返すことを確認"""
        # 実行
        response = app.lambda_handler(apigw_event, lambda_context)
        
        # 検証
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    def test_lambda_handler_returns_valid_json_structure(self, apigw_event, lambda_context):
        """BF-03: API Gateway準拠のレスポンス構造を確認"""
        # 実行
        response = app.lambda_handler(apigw_event, lambda_context)
        
        # 検証: 必須フィールドの存在確認
        assert "statusCode" in response
        assert "body" in response
        
        # フィールドの型確認
        assert isinstance(response["statusCode"], int)
        assert isinstance(response["body"], str)
        assert isinstance(response, dict)
        assert len(response) == 2  # statusCodeとbodyのみ
    
    def test_lambda_handler_body_is_valid_json(self, apigw_event, lambda_context):
        """BF-04: bodyフィールドが有効なJSON文字列であることを確認"""
        # 実行
        response = app.lambda_handler(apigw_event, lambda_context)
        
        # 検証: JSONとして解析可能であることを確認
        assert "body" in response
        body = json.loads(response["body"])  # 例外が発生しなければ有効なJSON
        assert isinstance(body, dict)
        
        # メッセージフィールドが存在することを確認
        assert "message" in body
        assert body["message"] == "hello world"
        
        # 予期しないフィールドがないことを確認
        expected_fields = {"message"}
        actual_fields = set(body.keys())
        assert actual_fields == expected_fields


class TestLambdaHandlerEdgeCases:
    """エッジケーステスト"""
    
    def test_lambda_handler_with_none_event(self, lambda_context):
        """EC-01: eventがNoneの場合でも正常動作することを確認"""
        # 実行
        response = app.lambda_handler(None, lambda_context)
        
        # 検証: Noneでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    def test_lambda_handler_with_empty_event(self, lambda_context):
        """EC-02: eventが空辞書の場合でも正常動作することを確認"""
        # 実行
        response = app.lambda_handler({}, lambda_context)
        
        # 検証: 空のイベントでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    def test_lambda_handler_with_none_context(self, apigw_event):
        """EC-03: contextがNoneの場合でも正常動作することを確認"""
        # 実行
        response = app.lambda_handler(apigw_event, None)
        
        # 検証: コンテキストがNoneでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    def test_lambda_handler_with_complex_event(self, apigw_event, lambda_context):
        """EC-04: 複雑なAPI Gateway eventでも正常動作することを確認"""
        # 実行
        response = app.lambda_handler(apigw_event, lambda_context)
        
        # 検証: 複雑なイベントでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"


class TestLambdaHandlerRobustness:
    """堅牢性テスト"""
    
    def test_handler_with_malformed_event_structure(self, lambda_context):
        """不正な形式のイベント構造でのテスト"""
        malformed_events = [
            {"invalid": "structure"},
            {"body": None},
            {"headers": "not_a_dict"},
            {"queryStringParameters": "not_a_dict"},
        ]
        
        for event in malformed_events:
            # 実行
            response = app.lambda_handler(event, lambda_context)
            
            # 検証: 不正な形式でも正常に動作することを確認
            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert body["message"] == "hello world"
    
    def test_handler_with_both_none_inputs(self):
        """イベントとコンテキストが両方Noneの場合のテスト"""
        # 実行
        response = app.lambda_handler(None, None)
        
        # 検証: 両方がNoneでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"


class TestLambdaHandlerParameterized:
    """パラメータ化テスト"""
    
    @pytest.mark.parametrize("event_input,expected_status", [
        (None, 200),
        ({}, 200),
        ({"body": "test"}, 200),
        ({"headers": {"test": "value"}}, 200),
        ({"queryStringParameters": {"test": "value"}}, 200),
    ])
    def test_various_event_inputs(self, event_input, expected_status, lambda_context):
        """様々なイベント入力でのテスト"""
        # 実行
        response = app.lambda_handler(event_input, lambda_context)
        
        # 検証
        assert response["statusCode"] == expected_status
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    @pytest.mark.parametrize("context_input", [
        None,
        Mock(),
    ])
    def test_various_context_inputs(self, apigw_event, context_input):
        """様々なコンテキスト入力でのテスト"""
        # 実行
        response = app.lambda_handler(apigw_event, context_input)
        
        # 検証
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
        assert body["message"] == "hello world"
        # 実行
        response = app.lambda_handler(apigw_event, None)
        
        # 検証: コンテキストがNoneでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    def test_handler_with_both_none_inputs(self):
        """イベントとコンテキストが両方Noneの場合のテスト"""
        # 実行
        response = app.lambda_handler(None, None)
        
        # 検証: 両方がNoneでも正常に動作することを確認
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"


# パラメータ化テストによる包括的なテストケース
class TestLambdaHandlerParameterized:
    """パラメータ化テスト"""
    
    @pytest.mark.parametrize("event_input,expected_status", [
        (None, 200),
        ({}, 200),
        ({"body": "test"}, 200),
        ({"headers": {"test": "value"}}, 200),
        ({"queryStringParameters": {"test": "value"}}, 200),
    ])
    def test_various_event_inputs(self, event_input, expected_status, lambda_context):
        """様々なイベント入力でのテスト"""
        # 実行
        response = app.lambda_handler(event_input, lambda_context)
        
        # 検証
        assert response["statusCode"] == expected_status
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
    
    @pytest.mark.parametrize("context_input", [
        None,
        Mock(),
    ])
    def test_various_context_inputs(self, apigw_event, context_input):
        """様々なコンテキスト入力でのテスト"""
        # 実行
        response = app.lambda_handler(apigw_event, context_input)
        
        # 検証
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["message"] == "hello world"
