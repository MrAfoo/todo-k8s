"""FastAPI wrapper for MCP Server - HTTP API for Kubernetes deployment."""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from app.database import SessionLocal
from app.models.task import Task
from sqlalchemy.orm import Session

# Create FastAPI application for MCP Server
app = FastAPI(
    title="MCP Task Management Server",
    description="Model Context Protocol server for task management operations",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Internal service, can be more permissive
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Pydantic models for API
class TaskCreate(BaseModel):
    user_id: int
    title: str
    description: Optional[str] = None
    priority: Optional[str] = "medium"
    category: Optional[str] = None
    due_date: Optional[datetime] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    completed: Optional[bool] = None
    priority: Optional[str] = None
    category: Optional[str] = None
    due_date: Optional[datetime] = None


class TaskResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str]
    completed: bool
    priority: str
    category: Optional[str]
    due_date: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Health check endpoint (required by Kubernetes)
@app.get("/health")
@app.head("/health")
def health_check() -> dict:
    """Health check endpoint for Kubernetes probes."""
    return {"status": "healthy", "service": "mcp-server"}


@app.get("/")
def root() -> dict:
    """Root endpoint."""
    return {
        "message": "MCP Task Management Server",
        "version": "0.1.0",
        "docs": "/docs",
    }


# Task Management Endpoints
@app.post("/tasks", response_model=TaskResponse, status_code=201)
def create_task(task_data: TaskCreate) -> Task:
    """Create a new task."""
    db = next(get_db())
    try:
        task = Task(
            user_id=task_data.user_id,
            title=task_data.title,
            description=task_data.description,
            priority=task_data.priority,
            category=task_data.category,
            due_date=task_data.due_date,
            completed=False,
        )
        db.add(task)
        db.commit()
        db.refresh(task)
        return task
    finally:
        db.close()


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(task_id: int, user_id: int) -> Task:
    """Get a specific task."""
    db = next(get_db())
    try:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.user_id == user_id)
            .first()
        )
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        return task
    finally:
        db.close()


@app.get("/tasks", response_model=List[TaskResponse])
def list_tasks(user_id: int, completed: Optional[bool] = None) -> List[Task]:
    """List all tasks for a user."""
    db = next(get_db())
    try:
        query = db.query(Task).filter(Task.user_id == user_id)
        if completed is not None:
            query = query.filter(Task.completed == completed)
        tasks = query.order_by(Task.created_at.desc()).all()
        return tasks
    finally:
        db.close()


@app.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(task_id: int, user_id: int, task_data: TaskUpdate) -> Task:
    """Update a task."""
    db = next(get_db())
    try:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.user_id == user_id)
            .first()
        )
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")

        # Update fields if provided
        if task_data.title is not None:
            task.title = task_data.title
        if task_data.description is not None:
            task.description = task_data.description
        if task_data.completed is not None:
            task.completed = task_data.completed
        if task_data.priority is not None:
            task.priority = task_data.priority
        if task_data.category is not None:
            task.category = task_data.category
        if task_data.due_date is not None:
            task.due_date = task_data.due_date

        task.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(task)
        return task
    finally:
        db.close()


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, user_id: int) -> None:
    """Delete a task."""
    db = next(get_db())
    try:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.user_id == user_id)
            .first()
        )
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        
        db.delete(task)
        db.commit()
    finally:
        db.close()


@app.patch("/tasks/{task_id}/complete", response_model=TaskResponse)
def complete_task(task_id: int, user_id: int) -> Task:
    """Mark a task as completed."""
    db = next(get_db())
    try:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.user_id == user_id)
            .first()
        )
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        
        task.completed = True
        task.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(task)
        return task
    finally:
        db.close()


@app.patch("/tasks/{task_id}/incomplete", response_model=TaskResponse)
def incomplete_task(task_id: int, user_id: int) -> Task:
    """Mark a task as incomplete."""
    db = next(get_db())
    try:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.user_id == user_id)
            .first()
        )
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        
        task.completed = False
        task.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(task)
        return task
    finally:
        db.close()
