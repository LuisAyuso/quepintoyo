use serde_json;

use mongodb::bson;
use std::collections::BTreeMap as Map;

use std::sync::{RwLock, Arc};

use crate::db;
use crate::error;

use crate::conversion::*;

use std::default::Default;
use crypto::sha2::Sha256;

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

#[derive(Serialize, Deserialize, FromForm, Debug, Clone)]
pub struct UserData {
    pub user: String,
    pub password: String,
}

impl UserData {
    pub fn new(name: String, password: String) -> UserData {
        UserData {
            user: name,
            password: password,
        }
    }
}

serialize_tools!(UserData);

// =========================================================

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone)]
pub struct Token (String);

impl Token {
    pub fn new(name: &str) -> Result<Token, error::Crypto> {
        let header: jwt::Header = Default::default();
        let claims = jwt::Registered {
            iss: Some("quepintoyo.com".into()),
            sub: Some(name.into()),
            ..Default::default()
        };
        let token = jwt::Token::new(header, claims);
        let token = token.signed(b"quepintoyo secret", Sha256::new()).map_err(|_| error::Crypto::Signature)?;
        Ok(Token(token.into() ))
    }
}

impl std::string::ToString for Token {
    fn to_string(&self) -> String {
        self.0.clone()
    }
}

impl<'a, 'r> rocket::request::FromRequest<'a, 'r> for Token {
    type Error = crate::error::RequestError;

    fn from_request(request: &'a rocket::request::Request<'r>) -> rocket::request::Outcome<Self, Self::Error> {
        use rocket::Outcome::{Failure, Success};
        use rocket::http::Status;
        let keys: Vec<_> = request.headers().get("Authorization").collect();
        match keys.len() {
            0 => Failure((Status::Unauthorized, error::RequestError::NoToken)),
            1 => {
                println!("{}", keys[0]);
                let key = keys[0];
                if !key.starts_with("bearer "){
                    return Failure((Status::Unauthorized, error::RequestError::NoToken));
                }
                let (_, key) = key.split_at(7);

                let state  = request.guard::<rocket::State<AppState>>().expect("we must have a state");
                let tok = Token(key.to_string());
                state.tokens.write().map(|map|{
                            let session = map.get(&tok);
                            match session {
                                Some(_) => Success(Token("success".to_string())),
                                None =>   Failure((Status::Unauthorized, error::RequestError::NoToken)),
                        }
                        }).unwrap()
            }
            _ => Failure((Status::Unauthorized, error::RequestError::NoToken)),
        }
    }
}

// =========================================================

pub struct AppState {
    pub db: db::Connection,
    pub tokens: Arc<RwLock<Map<Token, UserData>>>,
}

impl AppState {
    pub fn new(conn: db::Connection) -> AppState {
        AppState {
            db: conn,
            tokens: Arc::new(RwLock::new(Map::new())),
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

    #[test]
    fn conversion() {
        let _data = UserData::new("abc".to_string(), "abc".to_string());
    }
}
