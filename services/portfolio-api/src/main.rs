mod app_state;
mod cache;
mod db;
mod handlers;
mod models;
mod repositories;
mod routes;
#[cfg(test)]
mod test_utils;

use crate::app_state::AppState;
use crate::cache::AppCache;
use tokio::net::TcpListener;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .init();

    let pool = db::init_pool().await;
    let cache = AppCache::new();
    let state = AppState { pool, cache };

    let app = routes::create_router(state);
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    tracing::info!("listening on http://0.0.0.0:8080");
    axum::serve(listener, app).await.unwrap();
}
