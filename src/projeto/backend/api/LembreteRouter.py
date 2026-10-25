from fastapi import APIRouter, Depends, status
from core.database import get_db
from services.LembreteService import LembreteService
from sqlalchemy.orm import Session
from repositories.LembreteRepository import LembreteRepository
from schemas.LembreteSchema import (
    LembreteAtualizarRequest,
    LembreteRequest,
    LembreteResponse
)

