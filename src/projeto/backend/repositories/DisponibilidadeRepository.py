from sqlalchemy import select 
from sqlalchemy.orm import Session

from models.Disponibilidade import Disponibilidade

class DisponibilidadeRepository:
    def __init__(self, db: Session):
        self.db = db 

    