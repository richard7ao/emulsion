use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Project {
    pub id: i64,
    pub portfolio_id: i64,
    pub title: String,
    pub role: String,
    pub writeup: String,
    pub screenshots: String,
    pub view_count: i64,
    pub interested_count: i64,
}
