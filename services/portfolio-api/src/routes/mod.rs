use axum::{routing::{get, post}, Router};
use tower_http::cors::CorsLayer;
use tower_http::services::ServeDir;
use tower_http::trace::TraceLayer;
use crate::app_state::AppState;
use crate::handlers;

#[cfg(test)]
mod tests;

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(handlers::health_handler::health))
        .route("/v1/portfolios/:id", get(handlers::portfolio_handler::get_portfolio))
        .route("/v1/portfolios/:id/view", post(handlers::portfolio_handler::post_view))
        .route("/v1/portfolios/:id/interested", post(handlers::portfolio_handler::post_interested))
        .route("/v1/portfolios/:id/projects", get(handlers::projects_handler::list_projects))
        .route("/v1/projects/:id", get(handlers::projects_handler::get_project))
        .route("/v1/projects/:id/view", post(handlers::projects_handler::post_project_view))
        .route("/v1/projects/:id/interested", post(handlers::projects_handler::post_interested))
        .route("/v1/portfolios/:id/qa", get(handlers::qa_handler::list_qa))
        .route("/v1/portfolios/:id/qa/ask", post(handlers::qa_handler::ask))
        .route("/v1/portfolios/:id/ama", post(handlers::qa_handler::post_ama_question))
        .route("/v1/portfolios/:id/notes", post(handlers::notes_handler::create_note).get(handlers::notes_handler::list_notes))
        .route("/v1/portfolios/:id/conversations", get(handlers::conversations_handler::list_conversations))
        .route("/v1/conversations/:cid/messages", get(handlers::conversations_handler::get_messages).post(handlers::conversations_handler::post_message))
        .nest_service("/static", ServeDir::new("static"))
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive())
        .with_state(state)
}
