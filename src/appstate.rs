use serde_json;

use mongodb::bson;

use qpy_core::db;

// =========================================================

#[derive(Serialize, Deserialize, FromForm, Debug, Clone, Elm)]
pub struct UserData {
    pub user: String,
    pub password: String,
}

serialize_tools!(UserData);

// =========================================================

pub struct AppState {
    pub db: db::Connection,
}

impl AppState {
    pub fn new(conn: db::Connection) -> AppState {
        AppState {
            db: conn,
        }
    }
}

// =========================================================
