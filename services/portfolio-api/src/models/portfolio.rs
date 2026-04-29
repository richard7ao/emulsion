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

impl From<Portfolio> for emulsion_types::Portfolio {
    fn from(p: Portfolio) -> Self {
        Self {
            id: p.id,
            name: p.name,
            bio: p.bio,
            photo_path: p.photo_path,
            summary: p.summary,
            created_at: p.created_at,
            view_count: p.view_count,
            interested_count: p.interested_count,
        }
    }
}
