use bson;
use mongodb::{Client, ThreadedClient};
use mongodb::db::ThreadedDatabase;

#[cfg(test)]
const APPDB: &'static str = "testDB";
#[cfg(not(test))]
const APPDB: &'static str = "myApp";


#[derive(Debug)]
pub enum Error{
    ConnectionError,
    QuerryError,
    LogicalError
}

pub struct Connection{
    client: Client
}

impl Connection{
    pub fn new(host: &str, port: u16) -> Result<Connection, Error> {
        Ok(Connection{
            client: Client::connect(host, port).map_err(|_| Error::ConnectionError)?
        })
    }

    pub fn add_doc(&self, collection: &str, data: bson::Document) 
    -> Result<mongodb::coll::results::InsertOneResult, Error> {

        let db = self.client.db(APPDB);
        let coll = db.collection(collection);
        coll.insert_one(data, None).map_err(|_| Error::ConnectionError)
    }

    pub fn find(&self, collection: &str, query: bson::Document)  
    -> Result<mongodb::cursor::Cursor, Error>
    {
        let db = self.client.db(APPDB);
        let coll = db.collection(collection);
        coll.find(Some(query), None).map_err(|_| Error::ConnectionError)
    }

    pub fn delete(&self, collection: &str, query: bson::Document)  
    -> Result<i32, Error>
    {
        let db = self.client.db(APPDB);
        let coll = db.collection(collection);
        coll.delete_many(query, None).map_err(|_| Error::ConnectionError).map(|r| r.deleted_count )
    }
}

// =========================================================

pub fn hello(host: &str, port: u16) {
    let client = Client::connect(host, port)
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
            Some(&bson::Bson::String(ref title)) => println!("{}", title),
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
    fn conn_remote() {

        assert_eq!(APPDB, "testDB");
        let conn = Connection::new("192.168.0.2",  32773).expect("must connect");

        let query = doc!{
            "title": "Jaws",
        };
        conn.delete("movies", query).expect("must delete");

        let query = doc!{
            "title": "Jaws",
        };
        let cursor = conn.find("movies", query).expect("must go");
        assert_eq!(cursor.count(), 0);

        let doc = doc! { 
            "title": "Jaws",
            "array": [ 1, 2, 3 ],
        };
        conn.add_doc("movies", doc).expect("must add");

        let query = doc!{
            "title": "Jaws",
        };
        let cursor = conn.find("movies", query).expect("must go");
        assert_eq!(cursor.count(), 1);


        let query = doc!{
            "title": "Jaws",
        };
        let count = conn.delete("movies", query).expect("must delete");
        assert_eq!(count, 1);
    }
}