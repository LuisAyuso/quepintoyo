
#[macro_use]
extern crate rocket;

#[macro_use(bson, doc)]
extern crate mongodb;

#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate serde_json;


pub mod conversion;
pub mod error;
pub mod db;


use mongodb::bson;

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
    fn test_job(){

    }
}