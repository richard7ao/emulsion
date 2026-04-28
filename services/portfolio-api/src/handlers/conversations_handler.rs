use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::repositories::conversations_repo;

pub async fn list_conversations(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    let convos = conversations_repo::find_by_portfolio_id(&state.pool, portfolio_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!({
        "conversations": convos,
        "theatre": true
    })))
}

pub async fn get_messages(
    State(state): State<AppState>,
    Path(cid): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    let messages = conversations_repo::find_messages_by_conversation_id(&state.pool, cid)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!({
        "messages": messages,
        "theatre": true
    })))
}
