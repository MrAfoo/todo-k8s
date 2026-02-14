"""MCP Client for calling MCP server over HTTP."""

import httpx
from typing import Any
from app.config import settings


class MCPClient:
    """HTTP client for MCP server."""
    
    def __init__(self, base_url: str | None = None):
        """Initialize MCP client.
        
        Args:
            base_url: Base URL of MCP server. If not provided, uses settings.mcp_server_url
        """
        self.base_url = (base_url or settings.mcp_server_url).rstrip("/")
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def call_tool(self, tool_name: str, arguments: dict[str, Any]) -> dict[str, Any]:
        """Call an MCP tool via HTTP.
        
        Args:
            tool_name: Name of the tool to call
            arguments: Arguments to pass to the tool
            
        Returns:
            Tool result as a dictionary
            
        Raises:
            httpx.HTTPError: If the request fails
        """
        response = await self.client.post(
            f"{self.base_url}/tools/call",
            json={
                "name": tool_name,
                "arguments": arguments
            }
        )
        response.raise_for_status()
        return response.json()
    
    async def list_tools(self) -> list[dict[str, Any]]:
        """List available MCP tools.
        
        Returns:
            List of available tools with their schemas
        """
        response = await self.client.get(f"{self.base_url}/tools/list")
        response.raise_for_status()
        return response.json()
    
    async def health_check(self) -> dict[str, Any]:
        """Check MCP server health.
        
        Returns:
            Health status
        """
        response = await self.client.get(f"{self.base_url}/health")
        response.raise_for_status()
        return response.json()
    
    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()


# Singleton instance
_mcp_client_instance: MCPClient | None = None


def get_mcp_client() -> MCPClient:
    """Get or create the MCP client singleton instance."""
    global _mcp_client_instance
    if _mcp_client_instance is None:
        _mcp_client_instance = MCPClient()
    return _mcp_client_instance
