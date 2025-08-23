from ninja import NinjaAPI
from typing import Dict

api = NinjaAPI(title="HelloProject API", version="1.0.0")

@api.get("/")
def hello_world(request) -> Dict[str, str]:
    """Hello World endpoint for HelloProject"""
    return {"message": "Hello World! It Works!", "project": "HelloProject"}

@api.get("/health")
def health_check(request) -> Dict[str, str]:
    """Health check endpoint"""
    return {"status": "healthy", "service": "HelloProject API"}
