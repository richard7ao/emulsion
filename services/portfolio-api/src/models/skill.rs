use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Skill {
    pub id: i64,
    pub portfolio_id: i64,
    pub category: String,
    pub items: String,
}
