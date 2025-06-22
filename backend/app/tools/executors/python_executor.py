import subprocess
import tempfile
import os
import base64
import json
from pathlib import Path
from typing import Dict, Any, Optional, List
import logging

logger = logging.getLogger(__name__)

class PythonExecutor:
    """Clean, general-purpose Python code executor for educational simulations
    
    This executor provides a safe environment for Python code execution without
    hardcoded domain knowledge. Let the AI model decide implementation approaches.
    """
    
    def __init__(self, output_dir: str = "./data/temp"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Allowed imports for educational purposes
        self.allowed_imports = {
            'numpy', 'np', 'matplotlib', 'plt', 'scipy', 'sympy', 'sp',
            'pandas', 'pd', 'math', 'cmath', 'random', 'statistics',
            'collections', 'itertools', 'functools', 'operator',
            'json', 'csv', 'base64', 'io', 'pathlib', 'time', 'datetime',
            'fractions', 'decimal', 'copy', 'pickle', 're', 'string',
            'typing', 'dataclasses', 'enum', 'warnings', 'traceback',
            'imageio'  # For GIF creation if needed
        }
        
        # Security restrictions
        self.forbidden_functions = {
            'exec', 'eval', 'compile', '__import__', 'reload', 'execfile', 
            'exit', 'quit', 'subprocess', 'os.system', 'os.popen'
        }
        
        self.dangerous_patterns = [
            'import os', 'from os import', 'import subprocess', 
            'from subprocess import', '__builtins__', 'globals()', 'locals()',
            'open(', 'file(', 'input(', 'raw_input('
        ]
    
    def execute_code(self, code: str, include_plots: bool = True, 
                    timeout: int = 60, user_intent: str = "", 
                    model_info: Dict[str, str] = None) -> Dict[str, Any]:
        """
        Execute Python code and return results
        
        Args:
            code: Python code to execute
            include_plots: Whether to include plots
            timeout: Execution timeout in seconds
            user_intent: User's original message for context
            model_info: Information about the models being used
        """
        # Log model information for analysis
        if model_info:
            logger.info(f"🤖 Agent Model: {model_info.get('agent_model', 'unknown')}")
            logger.info(f"🔧 Tool Model: {model_info.get('tool_model', 'python_executor')}")
            logger.info(f"📝 User Intent: {user_intent[:100]}...")
        
        try:
            # Safety check
            safety_result = self._safety_check(code)
            if not safety_result["safe"]:
                return {
                    "success": False,
                    "error": f"Code contains unsafe operations: {safety_result['reason']}",
                    "output": "",
                    "plots": []
                }
            
            # Let the AI model decide on visualization approach
            # We only provide gentle guidance, not hardcoded fixes
            enhanced_code = self._prepare_enhanced_code(code, include_plots)
            
            # Execute code
            with tempfile.NamedTemporaryFile(mode='w', suffix='.py', 
                                           delete=False, encoding='utf-8') as f:
                f.write(enhanced_code)
                temp_file = f.name
            
            try:
                result = subprocess.run(
                    ['python', temp_file],
                    capture_output=True,
                    text=True,
                    timeout=timeout,
                    cwd=self.output_dir,
                    env=self._get_safe_environment()
                )
                
                # Process execution results
                execution_result = self._process_result(result, include_plots)
                
                # If execution failed, try minimal, general fixes only
                if not execution_result.get("success", False) and result.stderr:
                    logger.info("Code execution failed, attempting minimal general fixes...")
                    fixed_result = self._attempt_minimal_fixes(code, result.stderr, include_plots)
                    if fixed_result.get("success", False):
                        logger.info("Minimal fixes successful!")
                        return fixed_result
                
                return execution_result
                
            finally:
                try:
                    os.unlink(temp_file)
                except:
                    pass
                
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "error": f"Code execution timeout ({timeout} seconds)",
                "output": "",
                "plots": []
            }
        except Exception as e:
            logger.error(f"Code execution failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "output": "",
                "plots": []
            }
    
    def _safety_check(self, code: str) -> Dict[str, Any]:
        """Basic safety check for code"""
        for forbidden in self.forbidden_functions:
            if forbidden in code:
                return {"safe": False, "reason": f"Contains forbidden function: {forbidden}"}
        
        for pattern in self.dangerous_patterns:
            if pattern in code:
                return {"safe": False, "reason": f"Contains dangerous pattern: {pattern}"}
        
        if 'open(' in code and not any(safe in code for safe in ['StringIO', 'BytesIO']):
            return {"safe": False, "reason": "File operations not allowed"}
        
        return {"safe": True, "reason": "Code passed safety checks"}
    
    def _attempt_minimal_fixes(self, code: str, error_message: str, 
                              include_plots: bool) -> Dict[str, Any]:
        """Apply only minimal, general fixes - let AI handle specific issues"""
        
        fixed_code = code
        
        # Only fix the most common, general issues
        if "seaborn" in error_message.lower():
            logger.info("Fixing seaborn style issue...")
            fixed_code = fixed_code.replace("plt.style.use('seaborn')", "plt.style.use('default')")
            fixed_code = fixed_code.replace('plt.style.use("seaborn")', "plt.style.use('default')")
        
        if "cannot convert float NaN to integer" in error_message:
            logger.info("Adding NaN safety check...")
            if "import numpy as np" not in fixed_code:
                fixed_code = "import numpy as np\n" + fixed_code
            # Add basic NaN protection - let AI handle specific logic
            fixed_code = fixed_code.replace("int(", "int(np.nan_to_num(")
        
        # Try executing the minimally fixed code
        if fixed_code != code:
            try:
                enhanced_code = self._prepare_enhanced_code(fixed_code, include_plots)
                
                with tempfile.NamedTemporaryFile(mode='w', suffix='.py', 
                                               delete=False, encoding='utf-8') as f:
                    f.write(enhanced_code)
                    temp_file = f.name
                
                try:
                    result = subprocess.run(
                        ['python', temp_file],
                        capture_output=True,
                        text=True,
                        timeout=60,
                        cwd=self.output_dir,
                        env=self._get_safe_environment()
                    )
                    
                    return self._process_result(result, include_plots)
                    
                finally:
                    try:
                        os.unlink(temp_file)
                    except:
                        pass
                        
            except Exception as e:
                logger.error(f"Minimal fix attempt failed: {e}")
        
        return {"success": False, "error": "Could not apply minimal fixes"}
    
    def _get_safe_environment(self) -> Dict[str, str]:
        """Get safe environment variables"""
        env = os.environ.copy()
        # Fix Unicode encoding issues on Windows
        env['PYTHONIOENCODING'] = 'utf-8'
        return env
    
    def _prepare_enhanced_code(self, code: str, include_plots: bool) -> str:
        """Prepare enhanced code with comprehensive scientific libraries but no hardcoded logic"""
        
        setup_code = """
import sys
import warnings
warnings.filterwarnings('ignore')

# Core scientific computing libraries
import numpy as np
import math
import cmath
from fractions import Fraction
from decimal import Decimal
import random
import statistics
import time
from datetime import datetime, timedelta

# Matplotlib with clean configuration
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.patches import Circle, Rectangle, Polygon, Ellipse, Arc
from matplotlib.collections import LineCollection
import matplotlib.patches as patches
import matplotlib.gridspec as gridspec

# SciPy for advanced scientific computing
try:
    import scipy
    from scipy import integrate, optimize, interpolate, linalg, stats
    from scipy.integrate import odeint, solve_ivp, quad
    from scipy.optimize import minimize, fsolve, root
    from scipy.interpolate import interp1d, CubicSpline
    from scipy.special import factorial, gamma, beta
except ImportError:
    print("SciPy not available")

# SymPy for symbolic mathematics
try:
    import sympy as sp
    from sympy import symbols, diff, integrate as sp_integrate, solve, simplify
    from sympy import sin, cos, tan, exp, log, sqrt, pi, E, oo, I
    from sympy.physics import units
except ImportError:
    print("SymPy not available")

# Data handling
try:
    import pandas as pd
except ImportError:
    print("Pandas not available")

import json
import base64
from io import BytesIO, StringIO
from collections import defaultdict, Counter, deque
import itertools
import functools
import operator

# ImageIO for animations (optional)
try:
    import imageio
except ImportError:
    print("ImageIO not available - animations may be limited")

# Clean matplotlib configuration
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['figure.dpi'] = 100
plt.rcParams['font.size'] = 12
plt.rcParams['axes.labelsize'] = 14
plt.rcParams['axes.titlesize'] = 16
plt.rcParams['xtick.labelsize'] = 12
plt.rcParams['ytick.labelsize'] = 12
plt.rcParams['legend.fontsize'] = 12
plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.3
plt.rcParams['lines.linewidth'] = 2
plt.rcParams['axes.axisbelow'] = True

# Try seaborn for better styling (optional)
try:
    import seaborn as sns
    sns.set_style("whitegrid")
except ImportError:
    pass

# Physics/Math constants (commonly used)
g = 9.81  # gravitational acceleration (m/s²)
c = 299792458  # speed of light (m/s)
h = 6.62607015e-34  # Planck constant (J⋅s)
k_B = 1.380649e-23  # Boltzmann constant (J/K)
e = 1.602176634e-19  # elementary charge (C)
m_e = 9.1093837015e-31  # electron mass (kg)
m_p = 1.67262192369e-27  # proton mass (kg)

# Plot saving function
def save_plot_as_base64(fig=None, filename=None, dpi=150):
    if fig is None:
        fig = plt.gcf()
    
    fig.tight_layout()
    
    buffer = BytesIO()
    fig.savefig(buffer, format='png', dpi=dpi, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    buffer.seek(0)
    img_base64 = base64.b64encode(buffer.getvalue()).decode()
    buffer.close()
    
    if filename:
        with open(f"{filename}.json", "w") as f:
            json.dump({"image": img_base64, "type": "static"}, f)
    
    return img_base64

# Enhanced plt.show() function
original_show = plt.show
plot_counter = 0

def custom_show():
    global plot_counter
    plot_counter += 1
    fig = plt.gcf()
    save_plot_as_base64(fig, f"plot_{plot_counter}")
    plt.close(fig)

plt.show = custom_show

# Output capture system
class OutputCapture:
    def __init__(self):
        self.captured = []
    
    def write(self, text):
        self.captured.append(text)
        sys.__stdout__.write(text)
        sys.__stdout__.flush()
    
    def flush(self):
        sys.__stdout__.flush()

# Redirect output
output_capture = OutputCapture()
sys.stdout = output_capture

print("Educational Python environment ready!")
print("Available: numpy, matplotlib, scipy, sympy, pandas")
print("Let your creativity and knowledge guide the implementation!")

"""
        
        # Add user code with clear separation
        enhanced_code = setup_code + "\n\n# === USER CODE ===\n" + code
        
        # Add cleanup
        end_code = """

# === CLEANUP ===
# Save any remaining plots
if plt.get_fignums():
    for fig_num in plt.get_fignums():
        fig = plt.figure(fig_num)
        save_plot_as_base64(fig, f"plot_final_{fig_num}")
        plt.close(fig)

print(f"\\nExecution completed! Generated {plot_counter} visualizations.")
"""
        
        return enhanced_code + end_code
    
    def _process_result(self, result: subprocess.CompletedProcess, 
                       include_plots: bool) -> Dict[str, Any]:
        """Process execution results"""
        response = {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else "",
            "plots": []
        }
        
        if include_plots:
            # Find generated plot files
            for json_file in self.output_dir.glob("*.json"):
                try:
                    with open(json_file, 'r') as f:
                        plot_data = json.load(f)
                        response["plots"].append(plot_data)
                    # Delete temporary file
                    json_file.unlink()
                except Exception as e:
                    logger.warning(f"Failed to process plot file: {e}")
                    continue
        
        return response
    
    def get_available_libraries(self) -> list:
        """Get list of available libraries"""
        return [
            "numpy - Numerical computing and arrays",
            "matplotlib - Plotting and visualization", 
            "scipy - Scientific computing (integration, optimization, etc.)",
            "sympy - Symbolic mathematics",
            "pandas - Data analysis and manipulation",
            "math/cmath - Basic and complex mathematical functions",
            "statistics - Statistical functions",
            "random - Random number generation",
            "imageio - Image and animation I/O",
            "Physics constants: g, c, h, k_B, e, m_e, m_p"
        ]
    
    def validate_syntax(self, code: str) -> Dict[str, Any]:
        """Validate code syntax"""
        try:
            compile(code, '<string>', 'exec')
            return {"valid": True, "error": None}
        except SyntaxError as e:
            return {
                "valid": False, 
                "error": f"Syntax error: {e.msg} (line {e.lineno})"
            }
        except Exception as e:
            return {"valid": False, "error": str(e)} 