from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
import logging
from app.services.knowledge_service import knowledge_service

logger = logging.getLogger(__name__)
router = APIRouter()

class KnowledgeSearchRequest(BaseModel):
    query: str = Field(..., description="搜索查询", min_length=1)
    category: str = Field(default="all", description="搜索类别 (physics/mathematics/all)")
    limit: int = Field(default=5, description="返回结果数量", ge=1, le=20)

class KnowledgeItem(BaseModel):
    title: str = Field(..., description="知识点标题")
    content: str = Field(..., description="知识点内容")
    category: str = Field(..., description="知识点类别")
    source: str = Field(..., description="知识来源")
    relevance_score: float = Field(..., description="相关性得分")

class KnowledgeSearchResponse(BaseModel):
    query: str = Field(..., description="搜索查询")
    results: List[KnowledgeItem] = Field(..., description="搜索结果")
    total_found: int = Field(..., description="找到的总数")
    category: str = Field(..., description="搜索类别")

@router.post("/knowledge/search", response_model=KnowledgeSearchResponse)
async def search_knowledge(request: KnowledgeSearchRequest):
    """
    搜索知识库
    
    支持的类别：
    - physics: 物理知识
    - mathematics: 数学知识  
    - all: 所有类别
    """
    try:
        logger.info(f"知识库搜索: {request.query} (类别: {request.category})")
        
        results = await knowledge_service.search(
            query=request.query,
            category=request.category,
            limit=request.limit
        )
        
        knowledge_items = []
        for item in results.get("results", []):
            knowledge_items.append(KnowledgeItem(
                title=item.get("title", ""),
                content=item.get("content", ""),
                category=item.get("category", ""),
                source=item.get("source", "unknown"),
                relevance_score=item.get("relevance_score", 0.0)
            ))
        
        return KnowledgeSearchResponse(
            query=request.query,
            results=knowledge_items,
            total_found=results.get("total_found", 0),
            category=request.category
        )
    
    except Exception as e:
        logger.error(f"知识库搜索失败: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"搜索知识库时发生错误: {str(e)}"
        )

@router.get("/knowledge/categories")
async def get_categories():
    """获取可用的知识类别"""
    try:
        categories = await knowledge_service.get_categories()
        return {
            "categories": categories,
            "total": len(categories)
        }
    except Exception as e:
        logger.error(f"获取知识类别失败: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"获取知识类别时发生错误: {str(e)}"
        )

@router.get("/knowledge/stats")
async def get_knowledge_stats():
    """获取知识库统计信息"""
    try:
        stats = await knowledge_service.get_stats()
        return stats
    except Exception as e:
        logger.error(f"获取知识库统计失败: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"获取知识库统计时发生错误: {str(e)}"
        )

@router.post("/knowledge/reload")
async def reload_knowledge_base():
    """重新加载知识库 (管理员功能)"""
    try:
        logger.info("开始重新加载知识库...")
        result = await knowledge_service.reload_knowledge_base()
        logger.info("知识库重新加载完成")
        return result
    except Exception as e:
        logger.error(f"重新加载知识库失败: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"重新加载知识库时发生错误: {str(e)}"
        )

@router.get("/knowledge/health")
async def knowledge_health():
    """知识库服务健康检查"""
    try:
        health = await knowledge_service.health_check()
        return health
    except Exception as e:
        logger.error(f"知识库健康检查失败: {e}")
        return {
            "status": "unhealthy",
            "error": str(e)
        } 