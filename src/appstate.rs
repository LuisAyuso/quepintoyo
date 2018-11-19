use serde_json;

use bson;

use crate::db;

// =========================================================

#[derive(Serialize, Deserialize, Debug)]
pub struct Task {
    pub name: String,
    pub done: bool
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Job {

    // #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing 
    pub id: i64,

    pub name: String,
    pub desc: Option<String>,
    pub tasks: Option<Vec<Task>>,
    pub photos: Option<Vec<String>>
}

impl Job {
    pub fn add_task(&mut self, task: Task){
        match &mut self.tasks 
        {
            Some(v) => { v.push(task); },
            None => { self.tasks = Some(vec!(task)); }
        }
    }

    pub fn to_json(&self) -> Result<String, serde_json::error::Error>{
        serde_json::to_string(self)
    }

    pub fn to_bson(&self) -> Result<bson::Bson,  bson::EncoderError>{
        bson::to_bson(self)
    }
}

// =========================================================

pub struct AppState {
    pub db: db::Connection
}

impl AppState{

    pub fn new(conn: db::Connection)-> AppState{
        AppState {
            db: conn
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

        let mut job = Job{
            id :  0, // bson::oid::ObjectId::new().expect("can not generate oid"),
            name : "the name".to_string(),
            desc : Some("a description".to_string()),
            tasks : None,
            photos : None
        };

        job.add_task(Task{ name : "task1".to_string(), done : false});


        let bson = job.to_bson().expect("to bson");
        if let bson::Bson::Document(document) = bson {
            assert_eq!(document.len(), 5);
        }
        else{
            assert!(false);
        }

        let json = job.to_json().expect("to json");
        println!("{}", json);
        assert_eq!(json, 
                   r#"{"id":0,"name":"the name","desc":"a description","tasks":[{"name":"task1","done":false}],"photos":null}"#);
    }
}