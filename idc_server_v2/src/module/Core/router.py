from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def get_module1_items():
    return {"message": "Module 1 Root"}

@router.get("/{item_id}")
def get_module1_item(item_id: int):
    return {"module": 1, "item_id": item_id}