mod app_state;
mod cache;
mod db;
mod error;
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

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port);
    let listener = TcpListener::bind(&addr).await.unwrap_or_else(|e| {
        panic!("failed to bind to {}: {}", addr, e);
    });
    tracing::info!("listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}
