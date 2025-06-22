from datasets import load_dataset
from typing import List, Dict, Any, Optional
import logging
from pathlib import Path
import pickle
import hashlib
import asyncio
import re

logger = logging.getLogger(__name__)

class OpenStaxLoader:
    """OpenStax教材数据加载器 - 使用datasets库加载crumb/openstax-text"""
    
    def __init__(self, cache_dir: str = "./data/knowledge_cache"):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.dataset_name = "crumb/openstax-text"
        
    def load_dataset(self, 
                    subjects: Optional[List[str]] = None,
                    force_reload: bool = False) -> List[Dict[str, Any]]:
        """
        加载OpenStax数据集
        
        Args:
            subjects: 要加载的学科列表 (如 ['physics', 'calculus'])
            force_reload: 是否强制重新加载
        """
        try:
            # 检查缓存
            cache_key = self._generate_cache_key(subjects)
            cache_file = self.cache_dir / f"openstax_{cache_key}.pkl"
            
            if not force_reload and cache_file.exists():
                logger.info(f"从缓存加载OpenStax数据: {cache_file}")
                with open(cache_file, 'rb') as f:
                    return pickle.load(f)
            
            # 加载数据集
            logger.info(f"加载OpenStax数据集: {self.dataset_name}")
            
            try:
                # 使用datasets库加载数据
                ds = load_dataset(self.dataset_name)
                logger.info(f"数据集加载成功，包含以下分割: {list(ds.keys())}")
            except Exception as e:
                logger.error(f"加载datasets失败: {e}")
                # 如果失败，返回模拟数据用于测试
                return self._create_mock_data(subjects)
            
            # 处理数据
            processed_data = []
            for split in ds.keys():
                logger.info(f"处理数据分割: {split}")
                for i, item in enumerate(ds[split]):
                    # 过滤学科
                    if subjects and not self._matches_subjects(item, subjects):
                        continue
                    
                    # 处理文本内容
                    processed_item = self._process_item(item)
                    if processed_item:
                        processed_data.append(processed_item)
                    
                    # 限制数据量（避免内存问题）
                    if len(processed_data) >= 1000:
                        logger.info("达到数据量限制，停止加载")
                        break
                
                if len(processed_data) >= 1000:
                    break
            
            # 缓存结果
            with open(cache_file, 'wb') as f:
                pickle.dump(processed_data, f)
            
            logger.info(f"成功加载 {len(processed_data)} 条OpenStax记录")
            return processed_data
            
        except Exception as e:
            logger.error(f"加载OpenStax数据集失败: {e}")
            # 返回模拟数据
            return self._create_mock_data(subjects)
    
    def _process_item(self, item: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """处理单个数据项"""
        try:
            # 提取基本信息
            text = item.get('text', '').strip()
            if not text or len(text) < 50:  # 过滤太短的文本
                return None
            
            # 清理和处理文本
            cleaned_text = self._clean_text(text)
            chunks = self._chunk_text(cleaned_text, chunk_size=512)
            
            # 提取元数据
            metadata = {
                'source': 'openstax',
                'subject': self._extract_subject(item),
                'chapter': item.get('chapter', ''),
                'section': item.get('section', ''),
                'title': item.get('title', ''),
                'book': item.get('book', ''),
                'url': item.get('url', ''),
                'chunk_count': len(chunks)
            }
            
            return {
                'id': self._generate_id(item),
                'original_text': text,
                'cleaned_text': cleaned_text,
                'chunks': chunks,
                'metadata': metadata,
                'keywords': self._extract_keywords(cleaned_text)
            }
            
        except Exception as e:
            logger.error(f"处理数据项失败: {e}")
            return None
    
    def _extract_subject(self, item: Dict[str, Any]) -> str:
        """从数据项中提取学科信息"""
        # 尝试从多个字段提取学科
        possible_fields = ['subject', 'book', 'title', 'chapter']
        
        for field in possible_fields:
            value = item.get(field, '').lower()
            if not value:
                continue
            
            # 物理学科关键词
            if any(keyword in value for keyword in ['physics', 'mechanics', 'thermodynamics', 'electromagnetism', 'quantum']):
                return 'physics'
            
            # 数学学科关键词
            if any(keyword in value for keyword in ['calculus', 'algebra', 'mathematics', 'geometry', 'statistics']):
                return 'mathematics'
            
            # 其他学科
            if 'chemistry' in value:
                return 'chemistry'
            if 'biology' in value:
                return 'biology'
        
        return 'general'
    
    def _clean_text(self, text: str) -> str:
        """清理文本内容"""
        # 移除多余的空白字符
        text = re.sub(r'\s+', ' ', text)
        
        # 移除特殊字符（保留基本标点）
        text = re.sub(r'[^\w\s\.\,\;\:\!\?\-\(\)\[\]\"\'\/\=\+\*]', '', text)
        
        # 移除过长的数字序列（可能是ID或无意义数据）
        text = re.sub(r'\b\d{10,}\b', '', text)
        
        return text.strip()
    
    def _chunk_text(self, text: str, chunk_size: int = 512) -> List[str]:
        """将文本分块"""
        words = text.split()
        chunks = []
        
        for i in range(0, len(words), chunk_size):
            chunk = ' '.join(words[i:i + chunk_size])
            if len(chunk.strip()) > 20:  # 只保留有意义的块
                chunks.append(chunk)
        
        return chunks
    
    def _extract_keywords(self, text: str) -> List[str]:
        """提取关键词"""
        # 简单的关键词提取（可以后续改进为使用NLP库）
        words = text.lower().split()
        
        # 物理和数学关键词
        important_keywords = {
            'physics', 'force', 'energy', 'momentum', 'velocity', 'acceleration',
            'mass', 'charge', 'field', 'wave', 'frequency', 'amplitude',
            'calculus', 'derivative', 'integral', 'function', 'equation',
            'matrix', 'vector', 'algebra', 'geometry', 'statistics'
        }
        
        keywords = []
        for word in words:
            # 移除标点
            clean_word = re.sub(r'[^\w]', '', word)
            if clean_word in important_keywords:
                keywords.append(clean_word)
        
        return list(set(keywords))  # 去重
    
    def _matches_subjects(self, item: Dict[str, Any], subjects: List[str]) -> bool:
        """检查是否匹配指定学科"""
        item_subject = self._extract_subject(item)
        
        # 将physics映射到物理相关的关键词
        subject_mapping = {
            'physics': ['physics', 'mechanics', 'thermodynamics', 'electromagnetism'],
            'mathematics': ['mathematics', 'calculus', 'algebra', 'geometry', 'statistics'],
            'chemistry': ['chemistry'],
            'biology': ['biology']
        }
        
        for target_subject in subjects:
            target_keywords = subject_mapping.get(target_subject.lower(), [target_subject.lower()])
            if any(keyword in item_subject for keyword in target_keywords):
                return True
        
        return False
    
    def _generate_cache_key(self, subjects: Optional[List[str]]) -> str:
        """生成缓存键"""
        content = f"{self.dataset_name}_{subjects or 'all'}"
        return hashlib.md5(content.encode()).hexdigest()[:8]
    
    def _generate_id(self, item: Dict[str, Any]) -> str:
        """生成唯一ID"""
        content = f"{item.get('book', '')}_{item.get('chapter', '')}_{item.get('section', '')}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def _create_mock_data(self, subjects: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """创建模拟数据用于测试和离线使用"""
        logger.info("创建模拟数据...")
        
        mock_data = []
        
        # 物理学内容
        physics_content = [
            {
                "title": "牛顿第一定律",
                "text": "牛顿第一定律，也称为惯性定律，表明：一个物体如果不受外力作用或所受外力的合力为零，将保持静止状态或匀速直线运动状态。这个定律揭示了物体运动的基本性质：惯性。惯性是物体保持其运动状态不变的性质，质量是惯性大小的量度。",
                "subject": "physics",
                "chapter": "力与运动",
                "keywords": ["牛顿定律", "惯性", "力", "运动", "质量"]
            },
            {
                "title": "能量守恒定律",
                "text": "能量守恒定律是物理学中最重要的定律之一。它表明：在一个孤立系统中，能量既不能被创造也不能被销毁，只能从一种形式转换为另一种形式，而系统的总能量保持不变。常见的能量形式包括：动能、势能、热能、化学能、电能等。",
                "subject": "physics", 
                "chapter": "能量",
                "keywords": ["能量守恒", "动能", "势能", "热能", "转换"]
            },
            {
                "title": "简谐运动",
                "text": "简谐运动是最基本的周期性运动形式。当物体在平衡位置附近做往复运动，且回复力与位移成正比并指向平衡位置时，这种运动称为简谐运动。典型的例子包括：弹簧振子、单摆等。简谐运动的数学表达式为：x = A·cos(ωt + φ)，其中A是振幅，ω是角频率，φ是初相位。",
                "subject": "physics",
                "chapter": "振动与波",
                "keywords": ["简谐运动", "振幅", "频率", "周期", "弹簧", "单摆"]
            },
            {
                "title": "电磁感应",
                "text": "电磁感应现象由法拉第发现，描述了变化的磁场如何产生电场。法拉第电磁感应定律表明：闭合电路中的感应电动势等于通过该电路的磁通量变化率的负值。数学表达式为：ε = -dΦ/dt。这一定律是发电机、变压器等电气设备工作的基础。",
                "subject": "physics",
                "chapter": "电磁学",
                "keywords": ["电磁感应", "法拉第", "磁通量", "电动势", "发电机"]
            }
        ]
        
        # 数学内容
        math_content = [
            {
                "title": "导数的定义",
                "text": "导数是微积分学中的核心概念，描述了函数在某一点的瞬时变化率。函数f(x)在点x₀处的导数定义为：f'(x₀) = lim[h→0] [f(x₀+h) - f(x₀)]/h。几何意义上，导数表示函数图像在该点的切线斜率。导数在物理学中表示速度、加速度等概念。",
                "subject": "mathematics",
                "chapter": "微积分",
                "keywords": ["导数", "极限", "切线", "变化率", "微积分"]
            },
            {
                "title": "积分的概念",
                "text": "积分是微积分的另一个基本概念，与导数互为逆运算。定积分∫[a,b]f(x)dx表示函数f(x)在区间[a,b]上与x轴围成的有向面积。根据牛顿-莱布尼茨公式：∫[a,b]f(x)dx = F(b) - F(a)，其中F(x)是f(x)的原函数。积分在计算面积、体积、物理量等方面有广泛应用。",
                "subject": "mathematics", 
                "chapter": "微积分",
                "keywords": ["积分", "面积", "原函数", "牛顿", "莱布尼茨"]
            },
            {
                "title": "三角函数",
                "text": "三角函数是数学中最重要的初等函数之一。基本三角函数包括正弦函数sin(x)、余弦函数cos(x)和正切函数tan(x)。它们具有周期性：sin(x)和cos(x)的周期为2π，tan(x)的周期为π。三角函数在描述周期现象、波动、旋转等方面有广泛应用。",
                "subject": "mathematics",
                "chapter": "三角函数",
                "keywords": ["三角函数", "正弦", "余弦", "正切", "周期", "波动"]
            },
            {
                "title": "线性代数基础",
                "text": "线性代数研究向量、向量空间、线性变换和线性方程组。向量是具有大小和方向的量，可以进行加法和标量乘法运算。矩阵是数的矩形阵列，可以表示线性变换。行列式是方阵的一个标量值，用于判断矩阵是否可逆。线性代数在物理、工程、计算机科学等领域有重要应用。",
                "subject": "mathematics",
                "chapter": "线性代数", 
                "keywords": ["向量", "矩阵", "行列式", "线性变换", "向量空间"]
            }
        ]
        
        # 生成结构化数据
        all_content = physics_content + math_content
        
        for i, content in enumerate(all_content):
            # 过滤学科
            if subjects and content["subject"] not in subjects:
                continue
                
            # 处理文本
            cleaned_text = self._clean_text(content["text"])
            chunks = self._chunk_text(cleaned_text, chunk_size=256)
            
            item_data = {
                'id': f"mock_{content['subject']}_{i}",
                'original_text': content["text"],
                'cleaned_text': cleaned_text,
                'chunks': chunks,
                'metadata': {
                    'source': 'mock_openstax',
                    'subject': content["subject"],
                    'chapter': content["chapter"],
                    'section': '',
                    'title': content["title"],
                    'book': f"{content['subject'].title()} 基础教程",
                    'url': f"mock://openstax/{content['subject']}/{i}",
                    'chunk_count': len(chunks)
                },
                'keywords': content["keywords"]
            }
            
            mock_data.append(item_data)
        
        logger.info(f"创建了 {len(mock_data)} 条模拟数据")
        return mock_data
    
    def get_subjects(self) -> List[str]:
        """获取可用的学科列表"""
        return [
            'physics',
            'mathematics', 
            'chemistry',
            'biology'
        ]

# 使用示例
if __name__ == "__main__":
    loader = OpenStaxLoader()
    
    # 加载物理和数学内容
    data = loader.load_dataset(subjects=['physics', 'mathematics'])
    print(f"加载了 {len(data)} 条记录")
    
    # 查看第一条记录
    if data:
        print("\n示例记录:")
        print(f"标题: {data[0]['metadata']['title']}")
        print(f"学科: {data[0]['metadata']['subject']}")
        print(f"文本长度: {len(data[0]['original_text'])}")
        print(f"关键词: {data[0]['keywords'][:5]}") 