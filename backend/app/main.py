from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import logging
import os
from pathlib import Path
from app.core.config import settings
from app.api.v1 import chat
from app.core.claude_client import education_agent

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="Physics and Mathematics Education Assistant based on Claude Sonnet 4",
    version=settings.app_version,
    debug=settings.debug
)

# CORS settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create plots directory if it doesn't exist
plots_dir = Path("./data/temp")
plots_dir.mkdir(parents=True, exist_ok=True)

# Register routes
app.include_router(chat.router, prefix="/api/v1")

@app.get("/")
async def root():
    """Root path - API status"""
    return {
        "message": f"{settings.app_name} API service is running",
        "version": settings.app_version,
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Health check"""
    try:
        # Check Claude API connection
        api_status = education_agent.validate_api_key()
        
        return {
            "status": "healthy" if api_status else "degraded",
            "claude_api": "connected" if api_status else "disconnected",
            "version": settings.app_version
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "error": str(e)
            }
        )

@app.on_event("startup")
async def startup_event():
    """Application startup event"""
    logger.info(f"🚀 {settings.app_name} starting up...")
    logger.info(f"📖 Version: {settings.app_version}")
    logger.info(f"🔧 Debug mode: {settings.debug}")
    
    # Validate Claude API key
    if education_agent.validate_api_key():
        logger.info("✅ Claude API connection successful")
    else:
        logger.warning("⚠️ Claude API connection failed - please check API key")

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event"""
    logger.info(f"🛑 {settings.app_name} shutting down...")

@app.get("/api/plots/{filename}")
async def serve_plot(filename: str):
    """Serve generated plot images"""
    file_path = plots_dir / filename
    
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Plot not found")
    
    # Security check: ensure file is within plots directory
    try:
        file_path.resolve().relative_to(plots_dir.resolve())
    except ValueError:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return FileResponse(
        path=file_path,
        media_type="image/png",
        filename=filename
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    ) 