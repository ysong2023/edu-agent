from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
import logging
from app.core.claude_client import education_agent

logger = logging.getLogger(__name__)
router = APIRouter()

class ChatMessage(BaseModel):
    role: str = Field(..., description="消息角色 (user/assistant)")
    content: str = Field(..., description="消息内容")

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000, description="User message")
    history: Optional[List[Dict[str, Any]]] = Field(default=[], description="Conversation history")

class ToolResult(BaseModel):
    tool_name: str = Field(..., description="工具名称")
    result: Any = Field(..., description="工具执行结果")
    tool_id: str = Field(..., description="工具ID")
    error: Optional[str] = Field(default=None, description="错误信息")

class ChatResponse(BaseModel):
    message: str = Field(..., description="AI response message")
    tool_results: List[Dict[str, Any]] = Field(default=[], description="Tool execution results")
    type: str = Field(default="assistant", description="Response type")
    error: Optional[str] = Field(default=None, description="Error message if any")

@router.post("/chat")
async def chat_endpoint(request: ChatRequest):
    """Main chat endpoint for interacting with the AI assistant"""
    try:
        logger.info(f"Received chat request: {request.message[:50]}...")
        
        # Clean history to remove extra fields that might cause validation errors
        cleaned_history = []
        if request.history:
            for msg in request.history:
                # Only keep role and content fields, filter out plots and other extra fields
                cleaned_msg = {
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                }
                cleaned_history.append(cleaned_msg)
        
        logger.info(f"📝 Cleaned history: {len(cleaned_history)} messages")
        
                # Process message with Claude
        response = await education_agent.process_message(
            message=request.message,
            history=cleaned_history
        )
        
        logger.info(f"🔍 Claude response keys: {list(response.keys())}")
        logger.info(f"🔍 Response success: {response.get('success', 'unknown')}")
        
        # Handle error responses
        if not response.get("success", False):
            error_msg = response.get("error", "Unknown error occurred")
            logger.error(f"AI processing error: {error_msg}")
            raise HTTPException(
                status_code=500,
                detail=error_msg
            )
        
        # Extract plots from tool results
        plots = []
        tool_results = response.get("tool_results", [])
        for tool_result in tool_results:
            if tool_result.get("tool_name") == "python_execute":
                result_data = tool_result.get("result", {})
                if "plots" in result_data:
                    plots.extend(result_data["plots"])
        
        # Get response text with fallbacks
        response_text = response.get("response", "")
        if not response_text:
            response_text = response.get("text", "")
        if not response_text:
            response_text = "No response generated"
        
        # Return response in format expected by frontend
        final_response = {
            "message": response_text,
            "plots": plots,
            "tool_results": tool_results,
            "type": response.get("type", "assistant")
        }
        
        logger.info(f"✅ Returning response with {len(plots)} plots and {len(final_response['message'])} chars of text")
        return final_response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Chat endpoint error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    """
    流式聊天接口 (TODO: 实现流式响应)
    """
    # 这里可以实现Server-Sent Events (SSE)流式响应
    # 目前返回普通响应
    return await chat_endpoint(request)

@router.get("/chat/health")
async def health_check():
    """Health check endpoint for the chat service"""
    try:
        # Test Claude API connection
        api_valid = education_agent.validate_api_key()
        
        return {
            "status": "healthy" if api_valid else "degraded",
            "claude_api": "connected" if api_valid else "disconnected",
            "message": "Chat service is operational" if api_valid else "Claude API connection failed"
        }
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "unhealthy",
            "claude_api": "error",
            "message": f"Health check failed: {str(e)}"
        }

@router.post("/chat/validate")
async def validate_message(message: str):
    """验证消息格式和内容"""
    if not message or len(message.strip()) == 0:
        raise HTTPException(status_code=400, detail="消息不能为空")
    
    if len(message) > 10000:
        raise HTTPException(status_code=400, detail="消息长度超过限制")
    
    return {"valid": True, "message": "消息格式有效"} 