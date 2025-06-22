from typing import List, Dict, Any
import logging
import numpy as np
from sentence_transformers import SentenceTransformer
import asyncio

logger = logging.getLogger(__name__)

class SemanticRetriever:
    """语义检索器 - 使用句向量进行相似性搜索"""
    
    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        self.model_name = model_name
        self.model = None
        self.knowledge_embeddings = []
        self.knowledge_items = []
        self._initialized = False
    
    async def initialize(self, knowledge_data: List[Dict[str, Any]]):
        """初始化检索器"""
        try:
            logger.info(f"初始化语义检索器，模型: {self.model_name}")
            
            # 在线程中加载模型以避免阻塞
            self.model = await asyncio.to_thread(
                SentenceTransformer, self.model_name
            )
            
            # 处理知识数据
            texts = []
            self.knowledge_items = []
            
            for item in knowledge_data:
                # 使用清理后的文本进行embedding
                text = item.get('cleaned_text', '')
                if text:
                    texts.append(text)
                    self.knowledge_items.append(item)
            
            if texts:
                # 生成embeddings
                logger.info(f"为 {len(texts)} 条知识生成embeddings...")
                self.knowledge_embeddings = await asyncio.to_thread(
                    self.model.encode, texts
                )
                logger.info("语义检索器初始化完成")
            else:
                logger.warning("没有找到有效的文本数据")
            
            self._initialized = True
            
        except Exception as e:
            logger.error(f"初始化语义检索器失败: {e}")
            # 如果失败，使用简单的关键词匹配作为fallback
            self._initialized = False
    
    async def search(self, query: str, category: str = "all", 
                    limit: int = 5) -> List[Dict[str, Any]]:
        """搜索相关知识"""
        if not self._initialized or not self.knowledge_items:
            logger.warning("检索器未初始化，使用关键词搜索")
            return self._keyword_search(query, category, limit)
        
        try:
            # 生成查询embedding
            query_embedding = await asyncio.to_thread(
                self.model.encode, [query]
            )
            
            # 计算相似度
            similarities = np.dot(self.knowledge_embeddings, query_embedding.T).flatten()
            
            # 获取最相似的项目
            top_indices = np.argsort(similarities)[::-1]
            
            results = []
            for idx in top_indices:
                if len(results) >= limit:
                    break
                
                item = self.knowledge_items[idx]
                
                # 过滤类别
                if category != "all":
                    item_category = item.get('metadata', {}).get('subject', '')
                    if category.lower() not in item_category.lower():
                        continue
                
                # 只返回相似度较高的结果
                similarity_score = float(similarities[idx])
                if similarity_score > 0.1:  # 设置阈值
                    results.append({
                        'title': item.get('metadata', {}).get('title', '未知标题'),
                        'content': item.get('cleaned_text', '')[:500] + '...' if len(item.get('cleaned_text', '')) > 500 else item.get('cleaned_text', ''),
                        'category': item.get('metadata', {}).get('subject', ''),
                        'source': item.get('metadata', {}).get('source', 'unknown'),
                        'relevance_score': similarity_score
                    })
            
            return results
            
        except Exception as e:
            logger.error(f"语义搜索失败: {e}")
            return self._keyword_search(query, category, limit)
    
    def _keyword_search(self, query: str, category: str = "all", 
                       limit: int = 5) -> List[Dict[str, Any]]:
        """关键词搜索作为fallback"""
        logger.info("使用关键词搜索")
        
        query_words = set(query.lower().split())
        results = []
        
        for item in self.knowledge_items:
            # 过滤类别
            if category != "all":
                item_category = item.get('metadata', {}).get('subject', '')
                if category.lower() not in item_category.lower():
                    continue
            
            # 计算关键词匹配度
            text = item.get('cleaned_text', '').lower()
            text_words = set(text.split())
            
            # 计算交集
            common_words = query_words.intersection(text_words)
            if common_words:
                relevance_score = len(common_words) / len(query_words)
                
                results.append({
                    'title': item.get('metadata', {}).get('title', '未知标题'),
                    'content': item.get('cleaned_text', '')[:500] + '...' if len(item.get('cleaned_text', '')) > 500 else item.get('cleaned_text', ''),
                    'category': item.get('metadata', {}).get('subject', ''),
                    'source': item.get('metadata', {}).get('source', 'unknown'),
                    'relevance_score': relevance_score
                })
        
        # 按相关性排序
        results.sort(key=lambda x: x['relevance_score'], reverse=True)
        return results[:limit]
    
    def get_status(self) -> Dict[str, Any]:
        """获取检索器状态"""
        return {
            "initialized": self._initialized,
            "model_name": self.model_name,
            "knowledge_items_count": len(self.knowledge_items),
            "embeddings_shape": np.array(self.knowledge_embeddings).shape if self.knowledge_embeddings else None
        } 