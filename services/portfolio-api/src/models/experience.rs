use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Experience {
    pub id: i64,
    pub portfolio_id: i64,
    pub company: String,
    pub role: String,
    pub dates: String,
    pub bullets: String,
}
