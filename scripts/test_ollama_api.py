#!/usr/bin/env python3
"""
Test script for LocalAIChat - Tests Ollama API connection and basic functionality
"""

import requests
import time
import sys

OLLAMA_BASE_URL = "http://192.168.1.172:11434"
TEST_MODEL = ""  # Will use first available model

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    END = "\033[0m"

def log(msg, color=Colors.BLUE):
    print(f"{color}{msg}{Colors.END}")

def test_ollama_connection():
    """Test if Ollama server is running"""
    log("\n1. Testing Ollama connection...", Colors.BLUE)
    try:
        response = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        if response.status_code == 200:
            log("✓ Ollama server is running", Colors.GREEN)
            return True
        else:
            log(f"✗ Ollama returned status {response.status_code}", Colors.RED)
            return False
    except requests.exceptions.ConnectionError:
        log("✗ Cannot connect to Ollama - is it running?", Colors.RED)
        return False
    except Exception as e:
        log(f"✗ Error: {e}", Colors.RED)
        return False

def test_list_models():
    """Test listing available models"""
    log("\n2. Testing list models API...", Colors.BLUE)
    try:
        response = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        data = response.json()
        models = data.get("models", [])
        log(f"✓ Found {len(models)} model(s)", Colors.GREEN)
        for model in models:
            log(f"  - {model.get('name', 'unknown')}", Colors.YELLOW)
        return len(models) > 0
    except Exception as e:
        log(f"✗ Error: {e}", Colors.RED)
        return False

def test_generate_response():
    """Test basic generate endpoint"""
    log("\n3. Testing generate endpoint...", Colors.BLUE)
    try:
        payload = {
            "model": TEST_MODEL,
            "prompt": "Say 'Hello' in one word",
            "stream": False
        }
        start = time.time()
        response = requests.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload, timeout=30)
        elapsed = time.time() - start
        
        if response.status_code == 200:
            data = response.json()
            log(f"✓ Generate response in {elapsed:.2f}s", Colors.GREEN)
            log(f"  Response: {data.get('response', '').strip()}", Colors.YELLOW)
            return True
        else:
            log(f"✗ Generate returned status {response.status_code}", Colors.RED)
            return False
    except Exception as e:
        log(f"✗ Error: {e}", Colors.RED)
        return False

def test_chat_streaming():
    """Test chat endpoint with streaming"""
    log("\n4. Testing chat streaming endpoint...", Colors.BLUE)
    try:
        payload = {
            "model": TEST_MODEL,
            "messages": [
                {"role": "user", "content": "Count from 1 to 3"}
            ],
            "stream": True
        }
        
        start = time.time()
        response = requests.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload, timeout=30, stream=True)
        
        if response.status_code != 200:
            log(f"✗ Chat returned status {response.status_code}", Colors.RED)
            return False
        
        full_response = ""
        chunk_count = 0
        for line in response.iter_lines():
            if line:
                chunk_count += 1
                import json
                data = json.loads(line)
                if "message" in data:
                    full_response = data["message"].get("content", "")
        
        elapsed = time.time() - start
        log(f"✓ Streaming chat completed in {elapsed:.2f}s ({chunk_count} chunks)", Colors.GREEN)
        log(f"  Response: {full_response.strip()}", Colors.YELLOW)
        return True
    except Exception as e:
        log(f"✗ Error: {e}", Colors.RED)
        return False

def test_check_model_available():
    """Check if test model is available"""
    log("\n5. Checking if test model is available...", Colors.BLUE)
    try:
        response = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        data = response.json()
        models = [m.get("name", "") for m in data.get("models", [])]
        
        global TEST_MODEL
        if not TEST_MODEL and models:
            TEST_MODEL = models[0]
        
        if TEST_MODEL in models:
            log(f"✓ Model '{TEST_MODEL}' is available", Colors.GREEN)
            return True
        else:
            log(f"⚠ Model '{TEST_MODEL}' not found. Available models:", Colors.YELLOW)
            for m in models:
                log(f"  - {m}", Colors.YELLOW)
            return len(models) > 0
    except Exception as e:
        log(f"✗ Error: {e}", Colors.RED)
        return False

def main():
    log("=" * 50, Colors.BLUE)
    log("LocalAIChat - Ollama API Test Suite", Colors.BLUE)
    log("=" * 50, Colors.BLUE)
    
    results = []
    
    results.append(("Connection", test_ollama_connection()))
    
    if results[-1][1]:
        results.append(("List Models", test_list_models()))
        results.append(("Check Model", test_check_model_available()))
        
        if any(m.get("name") for m in requests.get(f"{OLLAMA_BASE_URL}/api/tags").json().get("models", [])):
            results.append(("Generate", test_generate_response()))
            results.append(("Chat Streaming", test_chat_streaming()))
        else:
            log("\n⚠ No models installed - skipping generate/chat tests", Colors.YELLOW)
            log("  Install a model with: ollama pull llama3.2", Colors.YELLOW)
    
    log("\n" + "=" * 50, Colors.BLUE)
    log("SUMMARY", Colors.BLUE)
    log("=" * 50, Colors.BLUE)
    
    passed = sum(1 for _, r in results if r)
    total = len(results)
    
    for name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        color = Colors.GREEN if result else Colors.RED
        log(f"{status} - {name}", color)
    
    log(f"\nTotal: {passed}/{total} tests passed", Colors.BLUE if passed == total else Colors.YELLOW)
    
    if total == 1:
        log("\n⚠ No models found - Ollama API works but needs a model installed", Colors.YELLOW)
        log("  Run: ollama pull llama3.2", Colors.YELLOW)
    
    return 0 if passed == total else 1

if __name__ == "__main__":
    sys.exit(main())
