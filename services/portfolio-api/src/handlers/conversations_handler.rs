use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde::Deserialize;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::error::AppError;
use crate::repositories::conversations_repo;

#[derive(Deserialize)]
pub struct SendMessage {
    pub sender: String,
    pub body: String,
}

pub async fn post_message(
    State(state): State<AppState>,
    Path(cid): Path<i64>,
    Json(msg): Json<SendMessage>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    if msg.sender.trim().is_empty() || msg.body.trim().is_empty() {
        return Err(AppError::BadRequest("sender and body are required".into()));
    }
    let id = conversations_repo::add_message(&state.pool, cid, &msg.sender, &msg.body).await?;
    Ok((StatusCode::CREATED, Json(json!({"id": id}))))
}

pub async fn list_conversations(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
) -> Result<Json<Value>, AppError> {
    let convos = conversations_repo::find_by_portfolio_id(&state.pool, portfolio_id).await?;
    Ok(Json(json!({
        "conversations": convos,
        "theatre": true
    })))
}

pub async fn get_messages(
    State(state): State<AppState>,
    Path(cid): Path<i64>,
) -> Result<Json<Value>, AppError> {
    let messages = conversations_repo::find_messages_by_conversation_id(&state.pool, cid).await?;
    Ok(Json(json!({
        "messages": messages,
        "theatre": true
    })))
}
