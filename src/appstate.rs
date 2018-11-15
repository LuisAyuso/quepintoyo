use std::sync::atomic::AtomicUsize;
use bson::*;

use crate::db;

// =========================================================

#[derive(Serialize, Deserialize, Debug)]
pub struct Task {
    pub name: String,
    pub done: bool
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Job {

    #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing 
    pub id: bson::oid::ObjectId,

    pub name: String,
    pub desc: Option<String>,
    pub tasks: Option<Vec<Task>>,
    pub photos: Option<Vec<String>>
}

impl Job {

}

// =========================================================

pub struct AppState {
    count: AtomicUsize
}

impl AppState{

    pub fn new()-> AppState{
        AppState {
            count: AtomicUsize::new(0)
        }
    }
}

// =========================================================

#[cfg(test)]
mod tests {

    use super::*;
    use bson;

    #[test]
    fn to_doc() {

        let job = Job{
            id :  bson::oid::ObjectId::new().expect("can not generate oid"),
            name : "the name".to_string(),
            desc : Some("a description".to_string()),
            tasks : None,
            photos : None
        };

        let encoded = bson::to_bson(&job).expect("serialized");

        if let bson::Bson::Document(document) = encoded {
            assert_eq!(document.len(), 5);
        }
        else{
            assert!(false);
        }
    }
}