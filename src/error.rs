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

impl std::convert::From<crate::error::Db> for rocket::http::Status {
    fn from(error: crate::error::Db) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::InternalServerError
    }
}

#[derive(Debug)]
pub enum Crypto {
    TimeError,
}

impl std::convert::From<crate::error::Crypto> for rocket::http::Status {
    fn from(error: crate::error::Crypto) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::InternalServerError
    }
}
