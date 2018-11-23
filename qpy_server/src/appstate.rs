use serde_json;

use mongodb::bson;


//use qpy_core::conversion::*;
use qpy_core::db;

// =========================================================

#[derive(Serialize, Deserialize, FromForm, Debug, Clone)]
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

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn to_doc() {
        let mut job = Job {
            id: 0, // bson::oid::ObjectId::new().expect("can not generate oid"),
            name: "the name".to_string(),
            desc: Some("a description".to_string()),
            tasks: None,
            photos: None,
        };

        job.add_task(Task {
            name: "task1".to_string(),
            done: false,
        });

        let bson_doc = job.to_bson().expect("to bson");
        assert_eq!(bson_doc.len(), 5);

        let json = job.to_json().expect("to json");
        println!("{}", json);
        assert_eq!(json, r#"{"id":0,"name":"the name","desc":"a description","tasks":[{"name":"task1","done":false}],"photos":null}"#);
    }
}
