use bson::Bson;
use mongodb::{Client, ThreadedClient};
use mongodb::db::ThreadedDatabase;

#[cfg(test)]
const APPDB: &'static str = "testDB";
#[cfg(not(test))]
const APPDB: &'static str = "myApp";

pub struct Connection{
    client: Client
}

impl Connection{
    pub fn new(host: &str, port: u16) -> Result<Connection, mongodb::error::Error> {
        Ok(Connection{
            client: Client::connect(host, port)?
        })
    }

    pub fn add_doc(&self, collection: &str, data: bson::Document) 
    -> Result<mongodb::coll::results::InsertOneResult, mongodb::error::Error> {

        let db = self.client.db(APPDB);
        let coll = db.collection(collection);
        coll.insert_one(data, None)
    }

}

// =========================================================

pub fn hello() {
    let client = Client::connect("localhost", 27017)
        .expect("Failed to initialize standalone client.");

    let coll = client.db("test").collection("movies");

    let doc = doc! { 
        "title": "Jaws",
        "array": [ 1, 2, 3 ],
    };

    // Insert document into 'test.movies' collection
    coll.insert_one(doc.clone(), None)
        .ok().expect("Failed to insert document.");

    // Find the document and receive a cursor
    let mut cursor = coll.find(Some(doc.clone()), None)
        .ok().expect("Failed to execute find.");

    let item = cursor.next();

    // cursor.next() returns an Option<Result<Document>>
    match item {
        Some(Ok(doc)) => match doc.get("title") {
            Some(&Bson::String(ref title)) => println!("{}", title),
            _ => panic!("Expected title to be a string!"),
        },
        Some(Err(_)) => panic!("Failed to get next from server!"),
        None => panic!("Server returned no results!"),
    }
}

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn connect() {

        assert_eq!(APPDB, "testDB");
        let conn = Connection::new("localhost", 27017).expect("must connect");

        let doc = doc! { 
            "title": "Jaws",
            "array": [ 1, 2, 3 ],
        };

        conn.add_doc(APPDB, doc).expect("must add");


    }
}