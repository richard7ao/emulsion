use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Note {
    pub id: i64,
    pub portfolio_id: i64,
    pub name: String,
    pub email: String,
    pub message: String,
    pub created_at: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateNote {
    pub name: String,
    #[serde(default)]
    pub email: String,
    pub message: String,
}
