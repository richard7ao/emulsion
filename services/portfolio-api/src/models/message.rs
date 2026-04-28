// Canonical type: emulsion_types::Message (shared/emulsion-types/src/lib.rs)
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Message {
    pub id: i64,
    pub conversation_id: i64,
    pub sender: String,
    pub body: String,
    pub created_at: String,
}
