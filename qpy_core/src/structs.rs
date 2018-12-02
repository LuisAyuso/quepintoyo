use mongodb::bson as bson;

// =========================================================


// =========================================================

#[derive(Serialize, Deserialize, Debug, Elm)]
pub struct Task {
    pub name: String,
    pub done: bool,
}

serialize_tools!(Task);

#[derive(Serialize, Deserialize, Debug)]
pub struct JobV1 {
    // #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing
    pub id: i64,
    pub user: String,
    pub name: String,
    pub desc: Option<String>,
    pub tasks: Option<Vec<Task>>,
    pub photos: Option<Vec<String>>,
}

serialize_tools!(JobV1);
serialize_tools!(Vec<JobV1>);

#[derive(Serialize, Deserialize, Debug)]
pub struct JobV2 {
    // #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing
    pub id: i64,
    pub user: String,
    pub name: String,
    pub date: f64,
    pub desc: Option<String>,
    pub tasks: Option<Vec<Task>>,
    pub photos: Option<Vec<String>>,
}

serialize_tools!(JobV2);
serialize_tools!(Vec<JobV2>);

impl From<JobV1> for JobV2{
    fn from(j: JobV1) -> JobV2 {
        JobV2{
            id : j.id,
            user: j.user,
            name: j.name,
            date: 0f64,
            desc: j.desc,
            tasks: j.tasks,
            photos: j.photos,
        }
    }
}


#[derive(Serialize, Deserialize, Debug, Elm)]
pub struct Job {
    // #[serde(rename = "_id")]  // Use MongoDB's special primary key field name when serializing
    pub id: i64,
    pub name: String,
    pub created: f64,
    pub lastmod: f64,
    pub desc: Option<String>,
    pub tasks: Option<Vec<Task>>,
    pub photos: Option<Vec<String>>,
}

serialize_tools!(Job);
serialize_tools!(Vec<Job>);

impl From<JobV2> for Job{
    fn from(j: JobV2) -> Job {
        Job{
            id : j.id,
            name: j.name,
            created: 0f64,
            lastmod: 0f64,
            desc: j.desc,
            tasks: j.tasks,
            photos: j.photos,
        }
    }
}
impl From<JobV1> for Job{
    fn from(j: JobV1) -> Job {
        let tmp : JobV2 = j.into();
        tmp.into()
    }
}
// =========================================================

#[derive(Serialize, Deserialize, Debug, Elm)]
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
    use crate::conversion::{Convert, VersionConvert};

    #[test]
    fn to_doc() {
        let job = JobV1 {
            id: 0, // bson::oid::ObjectId::new().expect("can not generate oid"),
            name: "the name".to_string(),
            user: "yo".to_string(),
            desc: Some("a description".to_string()),
            tasks: None,
            photos: None,
        };

        let bson_doc = job.to_bson().expect("to bson");
        assert_eq!(bson_doc.len(), 6);

        let json = job.to_json().expect("to json");
        println!("{}", json);
        assert_eq!(json, r#"{"id":0,"user":"yo","name":"the name","desc":"a description","tasks":null,"photos":null}"#);
    }

    #[test]
    fn versioning() {
        let v1 = JobV1{
            id: 0, // bson::oid::ObjectId::new().expect("can not generate oid"),
            name: "the name".to_string(),
            desc: Some("a description".to_string()),
            user: "yo".to_string(),
            tasks: None,
            photos: None,
        };
        let bson = v1.to_bson().expect("must convert");
        VersionConvert::<Job, JobV1>::version_from_bson(bson.clone()).expect("must convert");
        try_deserialize_bson!(bson.clone() => Job : JobV1).expect("must convert");
    }
}