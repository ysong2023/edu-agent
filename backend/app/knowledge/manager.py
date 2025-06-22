from typing import List, Dict, Any, Optional
import logging
import asyncio
from pathlib import Path

from app.knowledge.loaders.openstax_loader import OpenStaxLoader
from app.knowledge.retrievers.semantic_retriever import SemanticRetriever
from app.core.config import settings

logger = logging.getLogger(__name__)

class KnowledgeManager:
    """Knowledge Base Manager - Unified management of various knowledge sources"""
    
    def __init__(self):
        self.loaders = {
            'openstax': OpenStaxLoader(cache_dir=settings.knowledge_cache_dir)
        }
        self.retriever = SemanticRetriever()
        self.knowledge_data = []
        self._loaded = False
    
    async def initialize(self, force_reload: bool = False):
        """Initialize knowledge base"""
        if self._loaded and not force_reload:
            return
        
        logger.info("🔄 Initializing knowledge base...")
        
        try:
            # Load OpenStax data
            openstax_data = await self._load_openstax_data()
            self.knowledge_data.extend(openstax_data)
            
            # Initialize retriever
            await self.retriever.initialize(self.knowledge_data)
            
            self._loaded = True
            logger.info(f"✅ Knowledge base initialization complete, loaded {len(self.knowledge_data)} records")
            
        except Exception as e:
            logger.error(f"❌ Knowledge base initialization failed: {e}")
            raise
    
    async def _load_openstax_data(self) -> List[Dict[str, Any]]:
        """Load OpenStax data"""
        logger.info("📚 Loading OpenStax data...")
        
        # Focus on loading physics and mathematics content
        subjects = ['physics', 'calculus', 'algebra', 'statistics']
        
        openstax_loader = self.loaders['openstax']
        data = await asyncio.to_thread(
            openstax_loader.load_dataset,
            subjects=subjects,
            force_reload=False
        )
        
        logger.info(f"📖 OpenStax data loading complete: {len(data)} records")
        return data
    
    async def search(self, query: str, category: str = "all", 
                    limit: int = 5) -> Dict[str, Any]:
        """Search knowledge base"""
        if not self._loaded:
            await self.initialize()
        
        try:
            results = await self.retriever.search(
                query=query,
                category=category,
                limit=limit
            )
            
            return {
                "success": True,
                "query": query,
                "category": category,
                "results": results,
                "total_found": len(results)
            }
            
        except Exception as e:
            logger.error(f"Knowledge base search failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "results": []
            }
    
    async def get_categories(self) -> List[str]:
        """Get available knowledge categories"""
        if not self._loaded:
            await self.initialize()
        
        categories = set()
        for item in self.knowledge_data:
            if 'metadata' in item and 'subject' in item['metadata']:
                categories.add(item['metadata']['subject'])
        
        return sorted(list(categories))
    
    async def get_stats(self) -> Dict[str, Any]:
        """Get knowledge base statistics"""
        if not self._loaded:
            await self.initialize()
        
        categories = await self.get_categories()
        category_counts = {}
        
        for category in categories:
            count = sum(1 for item in self.knowledge_data 
                       if item.get('metadata', {}).get('subject') == category)
            category_counts[category] = count
        
        return {
            "total_items": len(self.knowledge_data),
            "categories": categories,
            "category_counts": category_counts,
            "sources": list(self.loaders.keys()),
            "loaded": self._loaded
        }
    
    async def reload_knowledge_base(self) -> Dict[str, Any]:
        """Reload knowledge base"""
        logger.info("🔄 Reloading knowledge base...")
        
        try:
            self._loaded = False
            self.knowledge_data = []
            
            await self.initialize(force_reload=True)
            
            return {
                "success": True,
                "message": "Knowledge base reloaded successfully",
                "total_items": len(self.knowledge_data)
            }
            
        except Exception as e:
            logger.error(f"Knowledge base reload failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    async def health_check(self) -> Dict[str, Any]:
        """Health check"""
        try:
            if not self._loaded:
                return {
                    "status": "uninitialized",
                    "message": "Knowledge base not initialized"
                }
            
            # Perform simple search test
            test_result = await self.search("physics", limit=1)
            
            if test_result["success"]:
                return {
                    "status": "healthy",
                    "total_items": len(self.knowledge_data),
                    "test_search": "passed"
                }
            else:
                return {
                    "status": "degraded",
                    "error": test_result.get("error", "Search test failed")
                }
                
        except Exception as e:
            logger.error(f"Knowledge base health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    def add_custom_knowledge(self, knowledge_items: List[Dict[str, Any]]):
        """Add custom knowledge items"""
        try:
            validated_items = []
            for item in knowledge_items:
                if self._validate_knowledge_item(item):
                    validated_items.append(item)
                else:
                    logger.warning(f"Skipped invalid knowledge item: {item}")
            
            self.knowledge_data.extend(validated_items)
            logger.info(f"Added {len(validated_items)} custom knowledge items")
            
        except Exception as e:
            logger.error(f"Failed to add custom knowledge: {e}")
    
    def _validate_knowledge_item(self, item: Dict[str, Any]) -> bool:
        """Validate knowledge item format"""
        required_fields = ['id', 'cleaned_text', 'metadata']
        
        for field in required_fields:
            if field not in item:
                return False
        
        return True

# Global instance
knowledge_manager = KnowledgeManager() 