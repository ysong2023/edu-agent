from typing import Dict, Any, List
import logging
from app.knowledge.manager import knowledge_manager

logger = logging.getLogger(__name__)

class KnowledgeService:
    """知识库服务层"""
    
    def __init__(self):
        self.manager = knowledge_manager
    
    async def search(self, query: str, category: str = "all", 
                    limit: int = 5) -> Dict[str, Any]:
        """搜索知识库"""
        return await self.manager.search(query, category, limit)
    
    async def get_categories(self) -> List[str]:
        """获取知识类别"""
        return await self.manager.get_categories()
    
    async def get_stats(self) -> Dict[str, Any]:
        """获取统计信息"""
        return await self.manager.get_stats()
    
    async def reload_knowledge_base(self) -> Dict[str, Any]:
        """重新加载知识库"""
        return await self.manager.reload_knowledge_base()
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        return await self.manager.health_check()

# 全局服务实例
knowledge_service = KnowledgeService() 