// Canonical type: emulsion_types::QaPair (shared/emulsion-types/src/lib.rs)
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct QaPair {
    pub id: i64,
    pub portfolio_id: i64,
    pub prompt: String,
    pub answer: String,
    pub is_canned: bool,
}
