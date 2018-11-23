#[derive(Debug)]
pub enum Conversion {
    BsonFailed,
    JsonFailed,
}

impl std::convert::From<crate::error::Conversion> for rocket::http::Status {
    fn from(error: crate::error::Conversion) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::InternalServerError
    }
}


#[derive(Debug)]
pub enum Db {
    ConnectionError,
    QuerryError,
    LogicalError,
    NotFound,
}

impl std::convert::From<Db> for rocket::http::Status {
    fn from(error: Db) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::InternalServerError
    }
}