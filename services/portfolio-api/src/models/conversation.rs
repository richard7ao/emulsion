// Canonical type: emulsion_types::Conversation (shared/emulsion-types/src/lib.rs)
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Conversation {
    pub id: i64,
    pub portfolio_id: i64,
    pub participant_name: String,
    pub last_message: String,
    pub updated_at: String,
}
