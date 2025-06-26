import json
import logging
from pathlib import Path
from typing import Dict, Any, List
from anthropic.types import ToolUseBlock

from app.tools.executors.python_executor import PythonExecutor

logger = logging.getLogger(__name__)

# Tool instances
python_executor = PythonExecutor()

def load_tool_schema(schema_name: str) -> Dict[str, Any]:
    """Load tool schema from JSON file"""
    try:
        schema_path = Path(__file__).parent / "schema" / f"{schema_name}.json"
        with open(schema_path, 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        logger.error(f"Failed to load tool schema {schema_name}: {e}")
        return {}

def get_all_tool_schemas() -> List[Dict[str, Any]]:
    """Get all available tool schemas (excluding knowledge_search)"""
    tool_names = [
        "education_context",
        "python_execute", 
        "physics_simulate",
        "math_visualize"
    ]
    
    schemas = []
    for tool_name in tool_names:
        schema = load_tool_schema(tool_name)
        if schema:
            schemas.append(schema)
            logger.info(f"✅ Loaded tool schema: {tool_name}")
        else:
            logger.warning(f"❌ Failed to load tool schema: {tool_name}")
    
    logger.info(f"📦 Total loaded tools: {len(schemas)}")
    return schemas

async def use_tool(tool_use_content: ToolUseBlock, model_info: Dict[str, str] = None) -> Any:
    """Execute tool based on tool use content"""
    tool_name = tool_use_content.name
    tool_input = tool_use_content.input
    
    logger.info(f"🔧 Executing tool: {tool_name}")
    if model_info:
        logger.info(f"🤖 Agent Model: {model_info.get('agent_model', 'unknown')}")
        logger.info(f"🔧 Tool Backend: {tool_name}")
        logger.info(f"📊 Tool Call Context: {model_info.get('context', 'unknown')}")
    
    # Route to appropriate tool function
    if tool_name == "education_context":
        return await _generate_education_context(tool_input, model_info)
    elif tool_name == "python_execute":
        return await _execute_python_code(tool_input, model_info)
    elif tool_name == "physics_simulate":
        return await _simulate_physics(tool_input, model_info)
    elif tool_name == "math_visualize":
        return await _visualize_math(tool_input, model_info)
    else:
        logger.error(f"Unknown tool: {tool_name}")
        return {
            "error": f"Unknown tool: {tool_name}",
            "success": False
        }

async def _generate_education_context(tool_input: Dict[str, Any], model_info: Dict[str, str] = None) -> Dict[str, Any]:
    """Generate educational context - let AI model provide the rich content"""
    topic = tool_input.get("topic", "")
    context_type = tool_input.get("context_type", "complete")
    target_audience = tool_input.get("target_audience", "general")
    
    logger.info(f"📚 Education context requested for topic: {topic}")
    if model_info:
        logger.info(f"📚 Content generation by: {model_info.get('agent_model', 'unknown')}")
    
    if not topic.strip():
        logger.error(f"📚 ERROR: Empty topic provided")
        return {"error": "Topic cannot be empty", "success": False}
    
    try:
        # This signals the AI to generate rich educational content
        result = {
            "success": True,
            "topic": topic,
            "context_type": context_type,
            "target_audience": target_audience,
            "signal": "GENERATE_EDUCATIONAL_CONTENT",
            "instructions": {
                "historical_background": "Provide fascinating historical context and discovery stories",
                "physical_principles": "Explain the fundamental concepts and elegant mathematical relationships",
                "related_knowledge": "Connect to other concepts and real-world applications",
                "ascii_diagrams": "Include helpful ASCII diagrams where appropriate"
            },
            "next_stage_required": True,
            "next_action": "MUST call python_execute tool for physics simulation"
        }
        
        logger.info(f"📚 Education context signal sent - awaiting AI content generation")
        return result
    
    except Exception as e:
        logger.error(f"Education context generation failed: {e}")
        return {"error": str(e), "success": False}

async def _execute_python_code(tool_input: Dict[str, Any], model_info: Dict[str, str] = None) -> Dict[str, Any]:
    """Execute Python code with model tracking"""
    code = tool_input.get("code", "")
    include_plots = tool_input.get("include_plots", True)
    timeout = tool_input.get("timeout", 30)
    user_intent = tool_input.get("user_intent", "")
    
    if not code.strip():
        return {"error": "Code cannot be empty", "success": False}
    
    try:
        result = python_executor.execute_code(
            code=code,
            include_plots=include_plots,
            timeout=timeout,
            user_intent=user_intent,
            model_info=model_info
        )
        
        return result
    
    except Exception as e:
        logger.error(f"Python code execution failed: {e}")
        return {
            "error": str(e),
            "success": False,
            "output": "",
            "plots": []
        }

async def _simulate_physics(tool_input: Dict[str, Any], model_info: Dict[str, str] = None) -> Dict[str, Any]:
    """Physics simulation - simplified, let AI decide the approach"""
    scenario = tool_input.get("scenario", "")
    parameters = tool_input.get("parameters", {})
    
    logger.info(f"⚡ Physics simulation requested: {scenario}")
    if model_info:
        logger.info(f"⚡ Simulation by: {model_info.get('agent_model', 'unknown')}")
    
    if not scenario.strip():
        return {"error": "Scenario cannot be empty", "success": False}
    
    try:
        # Simple mapping - let AI handle the complexity
        code_templates = {
            "projectile_motion": _get_simple_projectile_template(),
            "pendulum": _get_simple_pendulum_template(),
            "wave": _get_simple_wave_template(),
            "default": _get_generic_physics_template()
        }
        
        template = code_templates.get(scenario, code_templates["default"])
        code = template.format(**parameters) if parameters else template
        
        # Execute using python_execute
        return await _execute_python_code({
            "code": code,
            "include_plots": True,
            "user_intent": f"Physics simulation: {scenario}"
        }, model_info)
    
    except Exception as e:
        logger.error(f"Physics simulation failed: {e}")
        return {"error": str(e), "success": False}

async def _visualize_math(tool_input: Dict[str, Any], model_info: Dict[str, str] = None) -> Dict[str, Any]:
    """Math visualization - simplified, let AI decide the approach"""
    concept = tool_input.get("concept", "")
    parameters = tool_input.get("parameters", {})
    
    logger.info(f"📊 Math visualization requested: {concept}")
    if model_info:
        logger.info(f"📊 Visualization by: {model_info.get('agent_model', 'unknown')}")
    
    if not concept.strip():
        return {"error": "Concept cannot be empty", "success": False}
    
    try:
        # Simple templates - let AI provide the sophistication
        code_templates = {
            "derivative": _get_simple_derivative_template(),
            "integral": _get_simple_integral_template(),
            "function": _get_simple_function_template(),
            "default": _get_generic_math_template()
        }
        
        template = code_templates.get(concept, code_templates["default"])
        code = template.format(**parameters) if parameters else template
        
        return await _execute_python_code({
            "code": code,
            "include_plots": True,
            "user_intent": f"Math visualization: {concept}"
        }, model_info)
    
    except Exception as e:
        logger.error(f"Math visualization failed: {e}")
        return {"error": str(e), "success": False}

def _get_simple_projectile_template() -> str:
    """Simple projectile motion template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Simple projectile motion simulation
t = np.linspace(0, 10, 100)
x = 10 * t
y = 50 * t - 0.5 * 9.81 * t**2

plt.figure(figsize=(10, 6))
plt.plot(x, y)
plt.title('Projectile Motion')
plt.xlabel('Horizontal Distance (m)')
plt.ylabel('Height (m)')
plt.grid(True)
plt.show()
"""

def _get_simple_pendulum_template() -> str:
    """Simple pendulum template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Simple pendulum motion
t = np.linspace(0, 10, 1000)
theta = 0.2 * np.cos(np.sqrt(9.81/1.0) * t)

plt.figure(figsize=(10, 6))
plt.plot(t, theta)
plt.title('Simple Pendulum Motion')
plt.xlabel('Time (s)')
plt.ylabel('Angle (rad)')
plt.grid(True)
plt.show()
"""

def _get_simple_wave_template() -> str:
    """Simple wave template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Simple wave
x = np.linspace(0, 4*np.pi, 1000)
y = np.sin(x)

plt.figure(figsize=(10, 6))
plt.plot(x, y)
plt.title('Simple Wave')
plt.xlabel('Position')
plt.ylabel('Amplitude')
plt.grid(True)
plt.show()
"""

def _get_generic_physics_template() -> str:
    """Generic physics template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Generic physics visualization
x = np.linspace(0, 10, 100)
y = x**2

plt.figure(figsize=(10, 6))
plt.plot(x, y)
plt.title('Physics Visualization')
plt.xlabel('X')
plt.ylabel('Y')
plt.grid(True)
plt.show()
"""

def _get_simple_derivative_template() -> str:
    """Simple derivative template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Function and its derivative
x = np.linspace(-5, 5, 1000)
f = x**2
df = 2*x

plt.figure(figsize=(10, 6))
plt.plot(x, f, label='f(x) = x²')
plt.plot(x, df, label="f'(x) = 2x")
plt.title('Function and Derivative')
plt.xlabel('x')
plt.ylabel('y')
plt.legend()
plt.grid(True)
plt.show()
"""

def _get_simple_integral_template() -> str:
    """Simple integral template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Function and area under curve
x = np.linspace(0, 5, 1000)
y = x**2

plt.figure(figsize=(10, 6))
plt.plot(x, y, label='f(x) = x²')
plt.fill_between(x[:500], y[:500], alpha=0.3, label='Integral area')
plt.title('Function and Integral')
plt.xlabel('x')
plt.ylabel('y')
plt.legend()
plt.grid(True)
plt.show()
"""

def _get_simple_function_template() -> str:
    """Simple function template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Simple function
x = np.linspace(-10, 10, 1000)
y = np.sin(x)/x
y[x==0] = 1  # Handle division by zero

plt.figure(figsize=(10, 6))
plt.plot(x, y)
plt.title('Mathematical Function')
plt.xlabel('x')
plt.ylabel('y')
plt.grid(True)
plt.show()
"""

def _get_generic_math_template() -> str:
    """Generic math template"""
    return """
import numpy as np
import matplotlib.pyplot as plt

# Generic mathematical visualization
x = np.linspace(-5, 5, 1000)
y = np.exp(-x**2)

plt.figure(figsize=(10, 6))
plt.plot(x, y)
plt.title('Mathematical Visualization')
plt.xlabel('x')
plt.ylabel('y')
plt.grid(True)
plt.show()
"""

def get_tool_info() -> Dict[str, Any]:
    """Get information about available tools"""
    return {
        "available_tools": [
            "education_context",
            "python_execute",
            "physics_simulate", 
            "math_visualize"
        ],
        "python_libraries": python_executor.get_available_libraries(),
        "total_tools": 4
    } 