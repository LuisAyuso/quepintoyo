

#[derive(Debug)]
pub enum Crypto {
    TimeError,
    Signature,
    InvalidToken,
    InvalidUserName,
}

impl std::convert::From<crate::error::Crypto> for rocket::http::Status {
    fn from(error: crate::error::Crypto) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::InternalServerError
    }
}