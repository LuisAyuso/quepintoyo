
extern crate rocket;

#[macro_use( doc)]
extern crate mongodb;

#[macro_use]
extern crate serde_derive;
extern crate serde_json;

#[macro_use]
extern crate elm_generator;

pub mod conversion;
pub mod error;
pub mod db;


use mongodb::bson;

// =========================================================

#[derive(Serialize, Deserialize, Debug, Elm)]
pub struct Task {
    pub name: String,
    pub done: bool,
}

serialize_tools!(Task);

#[derive(Serialize, Deserialize, Debug, Elm)]
pub struct Job {
    // #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing
    pub id: i64,

    pub user: String,

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
serialize_tools!(Vec<Job>);

// =========================================================

// type alias Entry = 
//     { title: String
//     , content: String
//     , photos: Maybe (List Url)
//     , link: Maybe Url
//     }

#[derive(Serialize, Deserialize, Debug)]
pub struct NewsEntry {
    pub title: String,
    pub content: String,
    pub photos: Option<Vec<String>>,
    pub link: Option<String>,
}

serialize_tools!(NewsEntry);
serialize_tools!(Vec<NewsEntry>);

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
