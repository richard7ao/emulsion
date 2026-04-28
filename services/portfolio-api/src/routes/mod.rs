use axum::{routing::get, Router};
use tower_http::cors::CorsLayer;
use tower_http::services::ServeDir;
use crate::app_state::AppState;
use crate::handlers;

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(handlers::health_handler::health))
        .nest_service("/static", ServeDir::new("static"))
        .layer(CorsLayer::permissive())
        .with_state(state)
}
