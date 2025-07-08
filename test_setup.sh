#!/usr/bin/env bash

echo "🧪 Testing LiveKit + Ollama Setup"
echo "=================================="

# Test 1: LiveKit Server
echo "1. Testing LiveKit Server..."
if docker ps | grep -q livekit; then
    echo "   ✅ LiveKit server is running"
else
    echo "   ❌ LiveKit server is not running"
    exit 1
fi

# Test 2: Ollama
echo "2. Testing Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "   ✅ Ollama is responding"
    
    # Test model availability
    if curl -s http://localhost:11434/api/tags | grep -q "llama3.1"; then
        echo "   ✅ llama3.1 model is available"
    else
        echo "   ⚠️  llama3.1 model not found, available models:"
        curl -s http://localhost:11434/api/tags | jq '.models[].name' 2>/dev/null || curl -s http://localhost:11434/api/tags
    fi
else
    echo "   ❌ Ollama is not responding"
    exit 1
fi

# Test 3: Agent Process
echo "3. Testing Agent Process..."
if ps aux | grep -q "working_agent.py"; then
    echo "   ✅ Agent process is running"
else
    echo "   ❌ Agent process is not running"
    echo "   Starting agent..."
    cd backend
    source venv/bin/activate
    python working_agent.py &
    sleep 3
    if ps aux | grep -q "working_agent.py"; then
        echo "   ✅ Agent started successfully"
    else
        echo "   ❌ Failed to start agent"
        exit 1
    fi
fi

# Test 4: Frontend
echo "4. Testing Frontend..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "   ✅ Frontend is responding"
else
    echo "   ❌ Frontend is not responding"
    exit 1
fi

# Test 5: Token API
echo "5. Testing Token API..."
TOKEN_RESPONSE=$(curl -s "http://localhost:3000/api/token?room=test-room&username=test-user")
if echo "$TOKEN_RESPONSE" | grep -q "token"; then
    echo "   ✅ Token API is working"
else
    echo "   ❌ Token API failed: $TOKEN_RESPONSE"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Your setup is working correctly."
echo ""
echo "Next steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Allow microphone access"
echo "3. Speak to test voice interaction" 