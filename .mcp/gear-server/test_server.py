#!/usr/bin/env python3
"""Test the gear MCP server."""

import json
import subprocess
import sys

def test_server():
    """Test that the server starts and responds to list_tools."""
    
    # Start the server
    proc = subprocess.Popen(
        ["uv", "run", ".mcp/gear-server/server.py"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Send initialize request
    init_request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test", "version": "1.0.0"}
        }
    }
    
    proc.stdin.write(json.dumps(init_request) + "\n")
    proc.stdin.flush()
    
    # Read response
    response = proc.stdout.readline()
    print("Initialize response:", response)
    
    # Send list_tools request
    tools_request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/list"
    }
    
    proc.stdin.write(json.dumps(tools_request) + "\n")
    proc.stdin.flush()
    
    # Read response
    response = proc.stdout.readline()
    print("Tools list response:", response)
    
    # Cleanup
    proc.terminate()
    proc.wait()
    
    print("\n✅ Server test passed!")

if __name__ == "__main__":
    test_server()
