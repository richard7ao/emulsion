use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Portfolio {
    pub id: i64,
    pub name: String,
    pub bio: String,
    pub photo_path: Option<String>,
    pub summary: String,
    pub created_at: String,
    pub view_count: i64,
    pub interested_count: i64,
}
