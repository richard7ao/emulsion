use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde::Deserialize;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::repositories::{qa_repo, conversations_repo};

pub async fn list_qa(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    let pairs = qa_repo::find_canned_by_portfolio_id(&state.pool, portfolio_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
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
) -> Result<Json<Value>, StatusCode> {
    let result = qa_repo::fuzzy_match(&state.pool, portfolio_id, &body.query)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

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
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    let trimmed = body.query.trim();
    if trimmed.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let convo_id = conversations_repo::find_or_create_ama(&state.pool, portfolio_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let msg_id = conversations_repo::add_message(&state.pool, convo_id, "Visitor", trimmed)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok((StatusCode::CREATED, Json(json!({
        "conversation_id": convo_id,
        "message_id": msg_id
    }))))
}
