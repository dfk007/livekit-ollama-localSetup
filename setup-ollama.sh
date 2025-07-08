#!/usr/bin/env bash

echo "[*] Setting up Ollama..."

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "[!] Ollama is not installed. Installing..."
    
    # Install Ollama (Linux)
    curl -fsSL https://ollama.ai/install.sh | sh
    
    echo "[✓] Ollama installed. Please restart your terminal or run:"
    echo "    source ~/.bashrc"
    exit 0
fi

# Check if Ollama is running
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "[✓] Ollama is already running"
else
    echo "[*] Starting Ollama..."
    ollama serve &
    sleep 3
fi

# Check if llama3.1 model is available
if ollama list | grep -q "llama3.1"; then
    echo "[✓] llama3.1 model is available"
else
    echo "[*] Pulling llama3.1 model (this may take a while)..."
    ollama pull llama3.1
fi

echo "[✓] Ollama setup complete!" 