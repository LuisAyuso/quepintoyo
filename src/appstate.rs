use serde_json;

use mongodb::bson;

use crypto::sha2::Sha256;
use std::default::Default;

use crate::db;
use crate::error;
use crate::conversion::*;

// =========================================================

#[derive(Serialize, Deserialize, Debug)]
pub struct Task {
    pub name: String,
    pub done: bool,
}

serialize_tools!(Task);

#[derive(Serialize, Deserialize, Debug)]
pub struct Job {
    // #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing
    pub id: i64,

    pub name: String,
    pub desc: Option<String>,
    pub tasks: Option<Vec<Task>>,
    pub photos: Option<Vec<String>>,
}

impl Job {
    pub fn add_task(&mut self, task: Task) {
        match &mut self.tasks {
            Some(v) => {
                v.push(task);
            }
            None => {
                self.tasks = Some(vec![task]);
            }
        }
    }
}

serialize_tools!(Job);

// =========================================================

// type alias Entry = 
//     { title: String
//     , content: String
//     , photos: Maybe (List Url)
//     , link: Maybe Url
//     }

#[derive(Serialize, Deserialize, Debug)]
pub struct NewsEntry {
    title: String,
    content: String,
    photos: Option<Vec<String>>,
    link: Option<String>,
}

serialize_tools!(NewsEntry);

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
