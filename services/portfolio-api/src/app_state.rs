use sqlx::{Pool, Sqlite};
use crate::cache::AppCache;

#[derive(Clone)]
pub struct AppState {
    pub pool: Pool<Sqlite>,
    pub cache: AppCache,
}
