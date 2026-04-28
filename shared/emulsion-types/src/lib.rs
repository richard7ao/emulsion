uniffi::include_scaffolding!("emulsion_types");

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Experience {
    pub id: i64,
    pub portfolio_id: i64,
    pub company: String,
    pub role: String,
    pub dates: String,
    /// JSON-encoded Vec<String>. Stored this way to keep the schema flat;
    /// callers parse on render. A future migration would normalize this.
    pub bullets: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Skill {
    pub id: i64,
    pub portfolio_id: i64,
    pub category: String,
    /// JSON-encoded Vec<String>. See Experience.bullets.
    pub items: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Project {
    pub id: i64,
    pub portfolio_id: i64,
    pub title: String,
    pub role: String,
    pub writeup: String,
    /// JSON-encoded Vec<String>. See Experience.bullets.
    pub screenshots: String,
    pub view_count: i64,
    pub interested_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QAPair {
    pub id: i64,
    pub portfolio_id: i64,
    pub prompt: String,
    pub answer: String,
    pub is_canned: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Note {
    pub id: i64,
    pub portfolio_id: i64,
    pub name: String,
    pub email: String,
    pub message: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Conversation {
    pub id: i64,
    pub portfolio_id: i64,
    pub participant_name: String,
    pub last_message: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub id: i64,
    pub conversation_id: i64,
    pub sender: String,
    pub body: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PortfolioResponse {
    pub portfolio: Portfolio,
    pub experiences: Vec<Experience>,
    pub skills: Vec<Skill>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AskMatch {
    pub prompt: String,
    pub answer: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AskResponse {
    /// Wire format key is "match" (a Rust keyword), so the field is renamed.
    #[serde(rename = "match")]
    pub match_result: Option<AskMatch>,
    pub fallback: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationsResponse {
    pub conversations: Vec<Conversation>,
    pub theatre: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessagesResponse {
    pub messages: Vec<Message>,
    pub theatre: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn portfolio_roundtrip() {
        let p = Portfolio {
            id: 1,
            name: "Test".to_string(),
            bio: "Bio".to_string(),
            photo_path: None,
            summary: "Summary".to_string(),
            created_at: "2026-01-01 00:00:00".to_string(),
            view_count: 0,
            interested_count: 0,
        };
        let json = serde_json::to_string(&p).unwrap();
        let decoded: Portfolio = serde_json::from_str(&json).unwrap();
        assert_eq!(p.name, decoded.name);
        assert_eq!(p.id, decoded.id);
    }

    #[test]
    fn portfolio_response_contains_nested() {
        let resp = PortfolioResponse {
            portfolio: Portfolio {
                id: 1,
                name: "N".into(),
                bio: "B".into(),
                photo_path: Some("/photo.jpg".into()),
                summary: "S".into(),
                created_at: "".into(),
                view_count: 10,
                interested_count: 5,
            },
            experiences: vec![],
            skills: vec![],
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("\"name\":\"N\""));
        assert!(json.contains("\"experiences\":[]"));
    }

    #[test]
    fn ask_response_match_serializes_as_match_keyword() {
        let resp = AskResponse {
            match_result: Some(AskMatch {
                prompt: "p".into(),
                answer: "a".into(),
            }),
            fallback: None,
        };
        let json = serde_json::to_string(&resp).unwrap();
        // Wire format must be "match", not "match_result", for iOS compat.
        assert!(json.contains("\"match\":"), "expected \"match\" key, got: {}", json);
        assert!(!json.contains("match_result"), "leaked match_result key: {}", json);
    }

    #[test]
    fn ask_response_with_none_match() {
        let resp = AskResponse {
            match_result: None,
            fallback: Some("leave_a_note".into()),
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("\"fallback\":\"leave_a_note\""));
        assert!(json.contains("\"match\":null"));
    }
}
