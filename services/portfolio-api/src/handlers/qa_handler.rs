use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde::Deserialize;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::error::AppError;
use crate::repositories::{qa_repo, conversations_repo};

pub async fn list_qa(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
) -> Result<Json<Value>, AppError> {
    let pairs = qa_repo::find_canned_by_portfolio_id(&state.pool, portfolio_id).await?;
    Ok(Json(json!(pairs)))
}

#[derive(Deserialize)]
pub struct AskRequest {
    pub query: String,
}

pub async fn ask(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
    Json(body): Json<AskRequest>,
) -> Result<Json<Value>, AppError> {
    let result = qa_repo::fuzzy_match(&state.pool, portfolio_id, &body.query).await?;

    match result {
        Some(pair) => Ok(Json(json!({
            "match": {
                "prompt": pair.prompt,
                "answer": pair.answer,
            }
        }))),
        None => Ok(Json(json!({
            "match": null,
            "fallback": "leave_a_note"
        }))),
    }
}

pub async fn post_ama_question(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
    Json(body): Json<AskRequest>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    let trimmed = body.query.trim();
    if trimmed.is_empty() {
        return Err(AppError::BadRequest("query is required".into()));
    }

    let convo_id = conversations_repo::find_or_create_ama(&state.pool, portfolio_id).await?;
    let msg_id = conversations_repo::add_message(&state.pool, convo_id, "Visitor", trimmed).await?;

    Ok((StatusCode::CREATED, Json(json!({
        "conversation_id": convo_id,
        "message_id": msg_id
    }))))
}
