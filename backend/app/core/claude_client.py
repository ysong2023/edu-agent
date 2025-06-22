import anthropic
from typing import List, Dict, Any, Optional
import logging
from app.core.config import settings
from app.tools.manager import get_all_tool_schemas, use_tool

logger = logging.getLogger(__name__)

class EducationAgent:
    """Education AI Agent - Clean, AI-driven approach"""
    
    def __init__(self):
        self.client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
        self.model_name = "claude-3-5-sonnet-20241022"  # Track model version
        
        # Simplified, AI-driven system prompt
        self.system_prompt = """
You are an advanced Physics and Mathematics Teaching Agent that inspires deep understanding through your own knowledge and reasoning.

## CORE PHILOSOPHY:
**Trust your knowledge.** You have extensive understanding of physics, mathematics, and educational best practices. Use this knowledge to decide the best implementation approach for any concept.

## MANDATORY TWO-STAGE WORKFLOW:

### STAGE 1: EDUCATIONAL CONTEXT (REQUIRED)
**ALWAYS call education_context tool first**, then provide:

**Historical Background**:
- Who discovered/developed this concept and when?
- What was the historical context and scientific motivation? 
- What fascinating stories surround this discovery?
- How did this advance human understanding?

**Physical/Mathematical Principles**:
- What is the fundamental essence of this phenomenon?
- What are the key governing equations or mathematical relationships?
- Why does this behavior occur in nature?
- What makes this concept elegant or profound?
- Include ASCII diagrams when helpful for clarity

**Related Knowledge & Applications**:
- How does this connect to other concepts?
- Where do we see this in real-world applications?
- What implications does this have for technology or science?
- What questions might this inspire students to explore further?

### STAGE 2: AUTHENTIC IMPLEMENTATION (REQUIRED)  
**ALWAYS call python_execute tool second** with code that YOU design based on YOUR knowledge:

**Implementation Guidelines**:
- **YOU decide** whether to use static plots, animations, or interactive elements
- **YOU determine** the best way to visualize the concept
- **YOU choose** appropriate complexity level and mathematical detail
- **YOU implement** the physics/math from first principles using your knowledge
- Focus on authentic physical processes and real mathematical relationships
- Show actual quantities (time, energy, forces, derivatives, integrals)
- Compare different scenarios when educational valuable

**Available Tools**:

### 1. education_context
- Signals you to generate educational background using your knowledge
- Always call this FIRST for any physics/math question

### 2. python_execute  
- Execute Python code you design and implement
- Available libraries: numpy, matplotlib, scipy, sympy, pandas, imageio
- You decide: static vs animated, simple vs complex, 2D vs 3D
- You implement: the actual physics equations, mathematical derivations
- You choose: visualization style, complexity level, pedagogical approach

### 3. physics_simulate & math_visualize
- Simplified tools with basic templates
- YOU still provide the sophisticated implementation

## DECISION-MAKING AUTHORITY:

**You Decide Visualization Type**:
- Static plots for concept introduction or final results
- Animations for processes that evolve over time  
- Multiple frames for parameter comparison
- Interactive elements for exploration
- Decide based on what best serves educational goals

**You Decide Implementation Complexity**:
- Start simple for concept introduction
- Add sophistication for deeper exploration
- Include quantitative analysis when appropriate
- Balance accuracy with accessibility

**You Decide Educational Approach**:
- Conceptual first, then mathematical
- Historical context then modern applications  
- Simple examples building to complex scenarios
- Visual intuition supported by rigorous analysis

## CRITICAL REQUIREMENTS:
1. **MUST call education_context tool FIRST**
2. **MUST call python_execute tool SECOND with YOUR implementation**
3. **NEVER rely on hardcoded physics** - implement from your knowledge
4. **YOU choose the visualization approach** - static, animated, or interactive
5. **After both tools, provide synthesis and follow-up questions**

## EXAMPLES OF YOUR DECISION-MAKING:

### Example: Brachistochrone Problem
**Your Decision**: "I'll create an animation showing particles racing down different paths because seeing the motion makes the time difference visceral and educational."

**Your Implementation**:
```python
# I'll implement the cycloid parametric equations from first principles
# and animate particles moving along different curves to compare travel times
```

### Example: Wave Interference  
**Your Decision**: "I'll use a real-time animation to show wave propagation and interference pattern formation because this concept is fundamentally about time evolution."

**Your Implementation**:
```python
# I'll implement the wave equation and superposition principle
# with animation showing how interference patterns emerge over time
```

### Example: Thermodynamics
**Your Decision**: "I'll create a multi-panel static visualization showing different states and an energy flow diagram because the key insight is about relationships between state variables."

**Your Implementation**:
```python
# I'll implement the ideal gas law and first law of thermodynamics
# with clear visualizations of P-V diagrams and energy accounting
```

Remember: You are the expert. Trust your knowledge to make the best educational and implementation choices.
"""
    
    def get_model_info(self) -> Dict[str, str]:
        """Get current model information for logging"""
        return {
            "agent_model": self.model_name,
            "context": "educational_session",
            "approach": "ai_driven_implementation"
        }
    
    async def process_message(self, message: str, history: List[Dict] = None) -> Dict[str, Any]:
        """Process user message with model tracking"""
        
        logger.info(f"🤖 Processing message with {self.model_name}")
        logger.info(f"📝 User message: {message[:100]}...")
        
        try:
            messages = []
            
            # Add conversation history
            if history:
                messages.extend(history)
            
            # Add current user message
            messages.append({
                "role": "user",
                "content": message
            })
            
            # Get model info for tool calls
            model_info = self.get_model_info()
            
            # Call Claude API
            response = self.client.messages.create(
                model=self.model_name,
                max_tokens=4000,
                temperature=0.1,
                system=self.system_prompt,
                messages=messages,
                tools=get_all_tool_schemas()
            )
            
            # Process response with model info
            return await self._handle_response(response, messages, model_info)
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            return {
                "success": False,
                "error": str(e),
                "response": "Sorry, I encountered an error processing your request."
            }
    
    async def _handle_response(self, response, messages: List[Dict], model_info: Dict[str, str]) -> Dict[str, Any]:
        """Handle Claude response with tool execution tracking"""
        
        conversation_messages = messages.copy()
        
        # Add assistant response
        conversation_messages.append({
            "role": "assistant", 
            "content": response.content
        })
        
        response_text = ""
        tool_results = []
        
        # Process response content
        for content in response.content:
            if content.type == "text":
                response_text += content.text
            elif content.type == "tool_use":
                logger.info(f"🔧 Tool call detected: {content.name}")
                
                # Execute tool with model info
                tool_result = await use_tool(content, model_info)
                tool_results.append({
                    "tool_name": content.name,
                    "result": tool_result
                })
                
                # Add tool result to conversation
                conversation_messages.append({
                    "role": "user",
                    "content": [{
                        "type": "tool_result",
                        "tool_use_id": content.id,
                        "content": str(tool_result)
                    }]
                })
        
        # If tools were used, get follow-up response
        if tool_results:
            logger.info(f"🔄 Getting follow-up response after {len(tool_results)} tool calls")
            
            follow_up_response = self.client.messages.create(
                model=self.model_name,
                max_tokens=4000,
                temperature=0.1,
                system=self.system_prompt,
                messages=conversation_messages,
                tools=get_all_tool_schemas()  # Important: include tools for potential additional calls
            )
            
            # Process follow-up response - check for additional tool calls
            for content in follow_up_response.content:
                if content.type == "text":
                    response_text += "\n\n" + content.text
                elif content.type == "tool_use":
                    logger.info(f"🔧 Additional tool call detected: {content.name}")
                    
                    # Execute additional tool
                    additional_tool_result = await use_tool(content, model_info)
                    tool_results.append({
                        "tool_name": content.name,
                        "result": additional_tool_result
                    })
                    
                    # Add additional tool result to conversation
                    conversation_messages.append({
                        "role": "assistant",
                        "content": follow_up_response.content
                    })
                    conversation_messages.append({
                        "role": "user",
                        "content": [{
                            "type": "tool_result",
                            "tool_use_id": content.id,
                            "content": str(additional_tool_result)
                        }]
                    })
                    
                    # Get final response after additional tool
                    logger.info(f"🔄 Getting final response after additional tool: {content.name}")
                    final_response = self.client.messages.create(
                        model=self.model_name,
                        max_tokens=4000,
                        temperature=0.1,
                        system=self.system_prompt,
                        messages=conversation_messages
                    )
                    
                    # Add final response text
                    for final_content in final_response.content:
                        if final_content.type == "text":
                            response_text += "\n\n" + final_content.text
        
        return {
            "success": True,
            "response": response_text,
            "tool_results": tool_results,
            "conversation": conversation_messages,
            "model_info": model_info
        }
    
    def validate_api_key(self) -> bool:
        """Validate Anthropic API key"""
        try:
            # Test API key with a minimal request
            test_response = self.client.messages.create(
                model=self.model_name,
                max_tokens=10,
                messages=[{"role": "user", "content": "Hi"}]
            )
            return True
        except Exception as e:
            logger.error(f"API key validation failed: {e}")
            return False

# Global instance
education_agent = EducationAgent() 